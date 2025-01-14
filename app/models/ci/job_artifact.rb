# frozen_string_literal: true

module Ci
  class JobArtifact < Ci::ApplicationRecord
    include Ci::Partitionable
    include AfterCommitQueue
    include UpdateProjectStatistics
    include UsageStatistics
    include Sortable
    include Artifactable
    include Lockable
    include FileStoreMounter
    include EachBatch
    include Gitlab::Utils::StrongMemoize

    PLAN_LIMIT_PREFIX = 'ci_max_artifact_size_'

    InvalidArtifactError = Class.new(StandardError)

    self.table_name = :p_ci_job_artifacts
    self.primary_key = :id
    self.sequence_name = :ci_job_artifacts_id_seq

    partitionable scope: :job, partitioned: true
    query_constraints :id, :partition_id

    enum accessibility: { public: 0, private: 1, none: 2 }, _suffix: true

    belongs_to :project
    belongs_to :job,
      ->(artifact) { in_partition(artifact) },
      class_name: "Ci::Build",
      foreign_key: :job_id,
      partition_foreign_key: :partition_id,
      inverse_of: :job_artifacts

    has_one :artifact_report,
      ->(artifact) { in_partition(artifact) },
      class_name: 'Ci::JobArtifactReport',
      partition_foreign_key: :partition_id,
      inverse_of: :job_artifact

    mount_file_store_uploader JobArtifactUploader, skip_store_file: true
    update_project_statistics project_statistics_name: :build_artifacts_size

    before_save :set_size, if: :file_changed?
    after_save :store_file_in_transaction!, unless: :store_after_commit?

    after_create_commit :log_create

    after_commit :store_file_after_transaction!, on: [:create, :update], if: :store_after_commit?

    after_destroy_commit :log_destroy

    validates :job, presence: true
    validates :file_format, presence: true, unless: :trace?, on: :create
    validate :validate_file_format!, unless: :trace?, on: :create

    scope :not_expired, -> { where('expire_at IS NULL OR expire_at > ?', Time.current) }
    scope :for_sha, ->(sha, project_id) { joins(job: :pipeline).merge(Ci::Pipeline.for_sha(sha).for_project(project_id)) }
    scope :for_job_ids, ->(job_ids) { where(job_id: job_ids) }
    scope :for_job_name, ->(name) { joins(:job).merge(Ci::Build.by_name(name)) }
    scope :created_at_before, ->(time) { where(arel_table[:created_at].lteq(time)) }
    scope :id_before, ->(id) { where(arel_table[:id].lteq(id)) }
    scope :id_after, ->(id) { where(arel_table[:id].gt(id)) }
    scope :ordered_by_id, -> { order(:id) }
    scope :scoped_build, -> {
      where(arel_table[:job_id].eq(Ci::Build.arel_table[:id]))
      .where(arel_table[:partition_id].eq(Ci::Build.arel_table[:partition_id]))
    }

    scope :with_job, -> { joins(:job).includes(:job) }

    scope :with_file_types, ->(file_types) do
      types = self.file_types.select { |file_type| file_types.include?(file_type) }.values

      where(file_type: types)
    end

    scope :all_reports, -> do
      with_file_types(Enums::Ci::JobArtifact.report_types.keys.map(&:to_s))
    end

    scope :erasable, -> do
      where(file_type: self.erasable_file_types)
    end

    scope :non_trace, -> { where.not(file_type: [:trace]) }

    scope :downloadable, -> { where(file_type: Enums::Ci::JobArtifact.downloadable_types) }
    scope :unlocked, -> { joins(job: :pipeline).merge(::Ci::Pipeline.unlocked) }
    scope :order_expired_asc, -> { order(expire_at: :asc) }
    scope :with_destroy_preloads, -> { includes(project: [:route, :statistics, :build_artifacts_size_refresh]) }

    scope :for_project, ->(project) { where(project_id: project) }
    scope :created_in_time_range, ->(from: nil, to: nil) { where(created_at: from..to) }

    delegate :filename, :exists?, :open, to: :file
    enum file_type: Enums::Ci::JobArtifact.file_type

    # `file_location` indicates where actual files are stored.
    # Ideally, actual files should be stored in the same directory, and use the same
    # convention to generate its path. However, sometimes we can't do so due to backward-compatibility.
    #
    # legacy_path ... The actual file is stored at a path consists of a timestamp
    #                 and raw project/model IDs. Those rows were migrated from
    #                 `ci_builds.artifacts_file` and `ci_builds.artifacts_metadata`
    # hashed_path ... The actual file is stored at a path consists of a SHA2 based on the project ID.
    #                 This is the default value.
    enum file_location: Enums::Ci::JobArtifact.file_location

    def validate_file_format!
      unless Enums::Ci::JobArtifact.type_and_format_pairs[self.file_type&.to_sym] == self.file_format&.to_sym
        errors.add(:base, _('Invalid file format with specified file type'))
      end
    end

    def self.of_report_type(report_type)
      file_types = file_types_for_report(report_type)

      with_file_types(file_types)
    end

    def self.file_types_for_report(report_type)
      Enums::Ci::JobArtifact.report_file_types.fetch(report_type) { raise ArgumentError, "Unrecognized report type: #{report_type}" }
    end

    def self.associated_file_types_for(file_type)
      return unless file_types.include?(file_type)

      [file_type]
    end

    def self.erasable_file_types
      self.file_types.keys - Enums::Ci::JobArtifact.non_erasable_file_types
    end

    def self.total_size
      self.sum(:size)
    end

    def self.artifacts_size_for(project)
      self.where(project: project).sum(:size)
    end

    def self.pluck_job_id
      pluck(:job_id)
    end

    ##
    # FastDestroyAll concerns
    # rubocop: disable CodeReuse/ServiceClass
    def self.begin_fast_destroy
      service = ::Ci::JobArtifacts::DestroyAssociationsService.new(self)
      service.destroy_records
      service
    end
    # rubocop: enable CodeReuse/ServiceClass

    ##
    # FastDestroyAll concerns
    def self.finalize_fast_destroy(service)
      service.update_statistics
    end

    def local_store?
      [nil, ::JobArtifactUploader::Store::LOCAL].include?(self.file_store)
    end

    def hashed_path?
      return true if trace? # ArchiveLegacyTraces background migration might not have `file_location` column

      super || self.file_location.nil?
    end

    def expired?
      expire_at.present? && expire_at.past?
    end

    def expiring?
      expire_at.present? && expire_at.future?
    end

    def expire_in
      expire_at - Time.current if expire_at
    end

    def expire_in=(value)
      self.expire_at =
        (::Gitlab::Ci::Build::DurationParser.new(value).seconds_from_now if value)
    end

    def stored?
      file&.file&.exists?
    end

    def self.archived_trace_exists_for?(job_id)
      where(job_id: job_id).trace.take&.stored?
    end

    def self.max_artifact_size(type:, project:)
      limit_name = "#{PLAN_LIMIT_PREFIX}#{type}"

      max_size = project.actual_limits.limit_for(
        limit_name,
        alternate_limit: -> { project.closest_setting(:max_artifacts_size) }
      )

      max_size&.megabytes.to_i
    end

    def to_deleted_object_attrs(pick_up_at = nil)
      final_path_store_dir, final_path_filename = nil
      if file_final_path.present?
        final_path_store_dir = File.dirname(file_final_path)
        final_path_filename = File.basename(file_final_path)
      end

      {
        file_store: file_store,
        store_dir: final_path_store_dir || file.store_dir.to_s,
        file: final_path_filename || file_identifier,
        pick_up_at: set_pick_up_at(pick_up_at),
        project_id: project_id
      }
    end

    def store_after_commit?
      strong_memoize(:store_after_commit) do
        trace? && JobArtifactUploader.direct_upload_enabled?
      end
    end

    def public_access?
      public_accessibility?
    end

    def none_access?
      none_accessibility?
    end

    def each_blob(&blk)
      if junit? && artifact_report.nil?
        build_artifact_report(status: :validated, validation_error: nil, project_id: project_id)
      end

      super
    rescue InvalidArtifactError => e
      artifact_report&.assign_attributes(status: :faulty, validation_error: e.message)

      raise e
    ensure
      artifact_report&.save! if persisted?
    end

    private

    def set_pick_up_at(pick_up_at)
      (pick_up_at || expire_at || Time.current).clamp(1.day.ago, 1.hour.from_now)
    end

    def store_file_in_transaction!
      store_file_now! if saved_change_to_file?

      file_stored_in_transaction_hooks
    end

    def store_file_after_transaction!
      store_file_now! if previous_changes.key?(:file)

      file_stored_after_transaction_hooks
    end

    # method overridden in EE
    def file_stored_after_transaction_hooks; end

    # method overridden in EE
    def file_stored_in_transaction_hooks; end

    def set_size
      self.size = file.size
    end

    def project_destroyed?
      # Use job.project to avoid extra DB query for project
      job.project.pending_delete?
    end

    def log_create
      Gitlab::Ci::Artifacts::Logger.log_created(self)
    end

    def log_destroy
      Gitlab::Ci::Artifacts::Logger.log_deleted(self, __method__)
    end
  end
end

Ci::JobArtifact.prepend_mod_with('Ci::JobArtifact')
