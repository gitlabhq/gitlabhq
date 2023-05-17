# frozen_string_literal: true

module Ci
  class JobArtifact < Ci::ApplicationRecord
    include Ci::Partitionable
    include IgnorableColumns
    include AfterCommitQueue
    include UpdateProjectStatistics
    include UsageStatistics
    include Sortable
    include Artifactable
    include Lockable
    include FileStoreMounter
    include EachBatch
    include Gitlab::Utils::StrongMemoize

    enum accessibility: { public: 0, private: 1 }, _suffix: true

    NON_ERASABLE_FILE_TYPES = %w[trace].freeze

    REPORT_FILE_TYPES = {
      sast: %w[sast],
      secret_detection: %w[secret_detection],
      test: %w[junit],
      accessibility: %w[accessibility],
      coverage: %w[cobertura],
      codequality: %w[codequality],
      terraform: %w[terraform]
    }.freeze

    DEFAULT_FILE_NAMES = {
      archive: nil,
      metadata: nil,
      trace: nil,
      metrics_referee: nil,
      network_referee: nil,
      junit: 'junit.xml',
      accessibility: 'gl-accessibility.json',
      codequality: 'gl-code-quality-report.json',
      sast: 'gl-sast-report.json',
      secret_detection: 'gl-secret-detection-report.json',
      dependency_scanning: 'gl-dependency-scanning-report.json',
      container_scanning: 'gl-container-scanning-report.json',
      cluster_image_scanning: 'gl-cluster-image-scanning-report.json',
      dast: 'gl-dast-report.json',
      license_scanning: 'gl-license-scanning-report.json',
      performance: 'performance.json',
      browser_performance: 'browser-performance.json',
      load_performance: 'load-performance.json',
      metrics: 'metrics.txt',
      lsif: 'lsif.json',
      dotenv: '.env',
      cobertura: 'cobertura-coverage.xml',
      terraform: 'tfplan.json',
      cluster_applications: 'gl-cluster-applications.json', # DEPRECATED: https://gitlab.com/gitlab-org/gitlab/-/issues/361094
      requirements: 'requirements.json', # Will be DEPRECATED soon: https://gitlab.com/groups/gitlab-org/-/epics/9203
      requirements_v2: 'requirements_v2.json',
      coverage_fuzzing: 'gl-coverage-fuzzing.json',
      api_fuzzing: 'gl-api-fuzzing-report.json',
      cyclonedx: 'gl-sbom.cdx.json'
    }.freeze

    INTERNAL_TYPES = {
      archive: :zip,
      metadata: :gzip,
      trace: :raw
    }.freeze

    REPORT_TYPES = {
      junit: :gzip,
      metrics: :gzip,
      metrics_referee: :gzip,
      network_referee: :gzip,
      dotenv: :gzip,
      cobertura: :gzip,
      cluster_applications: :gzip, # DEPRECATED: https://gitlab.com/gitlab-org/gitlab/-/issues/361094
      lsif: :zip,
      cyclonedx: :gzip,

      # Security reports and license scanning reports are raw artifacts
      # because they used to be fetched by the frontend, but this is not the case anymore.
      sast: :raw,
      secret_detection: :raw,
      dependency_scanning: :raw,
      container_scanning: :raw,
      cluster_image_scanning: :raw,
      dast: :raw,
      license_scanning: :raw,

      # All these file formats use `raw` as we need to store them uncompressed
      # for Frontend to fetch the files and do analysis
      # When they will be only used by backend, they can be `gzipped`.
      accessibility: :raw,
      codequality: :raw,
      performance: :raw,
      browser_performance: :raw,
      load_performance: :raw,
      terraform: :raw,
      requirements: :raw,
      requirements_v2: :raw,
      coverage_fuzzing: :raw,
      api_fuzzing: :raw
    }.freeze

    DOWNLOADABLE_TYPES = %w[
      accessibility
      api_fuzzing
      archive
      cobertura
      codequality
      container_scanning
      dast
      dependency_scanning
      dotenv
      junit
      license_scanning
      lsif
      metrics
      performance
      browser_performance
      load_performance
      sast
      secret_detection
      requirements
      requirements_v2
      cluster_image_scanning
      cyclonedx
    ].freeze

    TYPE_AND_FORMAT_PAIRS = INTERNAL_TYPES.merge(REPORT_TYPES).freeze

    PLAN_LIMIT_PREFIX = 'ci_max_artifact_size_'

    belongs_to :project
    belongs_to :job, class_name: "Ci::Build", foreign_key: :job_id, inverse_of: :job_artifacts

    mount_file_store_uploader JobArtifactUploader, skip_store_file: true

    before_save :set_size, if: :file_changed?
    after_save :store_file_in_transaction!, unless: :store_after_commit?

    after_create_commit :log_create

    after_commit :store_file_after_transaction!, on: [:create, :update], if: :store_after_commit?

    after_destroy_commit :log_destroy

    validates :job, presence: true
    validates :file_format, presence: true, unless: :trace?, on: :create
    validate :validate_file_format!, unless: :trace?, on: :create

    update_project_statistics project_statistics_name: :build_artifacts_size
    partitionable scope: :job

    scope :not_expired, -> { where('expire_at IS NULL OR expire_at > ?', Time.current) }
    scope :for_sha, ->(sha, project_id) { joins(job: :pipeline).where(ci_pipelines: { sha: sha, project_id: project_id }) }
    scope :for_job_ids, ->(job_ids) { where(job_id: job_ids) }
    scope :for_job_name, ->(name) { joins(:job).merge(Ci::Build.by_name(name)) }
    scope :created_at_before, ->(time) { where(arel_table[:created_at].lteq(time)) }
    scope :id_before, ->(id) { where(arel_table[:id].lteq(id)) }
    scope :id_after, ->(id) { where(arel_table[:id].gt(id)) }
    scope :ordered_by_id, -> { order(:id) }

    scope :with_job, -> { joins(:job).includes(:job) }

    scope :with_file_types, -> (file_types) do
      types = self.file_types.select { |file_type| file_types.include?(file_type) }.values

      where(file_type: types)
    end

    scope :all_reports, -> do
      with_file_types(REPORT_TYPES.keys.map(&:to_s))
    end

    scope :erasable, -> do
      where(file_type: self.erasable_file_types)
    end

    scope :non_trace, -> { where.not(file_type: [:trace]) }

    scope :downloadable, -> { where(file_type: DOWNLOADABLE_TYPES) }
    scope :unlocked, -> { joins(job: :pipeline).merge(::Ci::Pipeline.unlocked) }
    scope :order_expired_asc, -> { order(expire_at: :asc) }
    scope :with_destroy_preloads, -> { includes(project: [:route, :statistics, :build_artifacts_size_refresh]) }

    scope :for_project, ->(project) { where(project_id: project) }
    scope :created_in_time_range, ->(from: nil, to: nil) { where(created_at: from..to) }

    delegate :filename, :exists?, :open, to: :file

    enum file_type: {
      archive: 1,
      metadata: 2,
      trace: 3,
      junit: 4,
      sast: 5, ## EE-specific
      dependency_scanning: 6, ## EE-specific
      container_scanning: 7, ## EE-specific
      dast: 8, ## EE-specific
      codequality: 9, ## EE-specific
      license_scanning: 101, ## EE-specific
      performance: 11, ## EE-specific till 13.2
      metrics: 12, ## EE-specific
      metrics_referee: 13, ## runner referees
      network_referee: 14, ## runner referees
      lsif: 15, # LSIF data for code navigation
      dotenv: 16,
      cobertura: 17,
      terraform: 18, # Transformed json
      accessibility: 19,
      cluster_applications: 20,
      secret_detection: 21, ## EE-specific
      requirements: 22, ## EE-specific
      coverage_fuzzing: 23, ## EE-specific
      browser_performance: 24, ## EE-specific
      load_performance: 25, ## EE-specific
      api_fuzzing: 26, ## EE-specific
      cluster_image_scanning: 27, ## EE-specific
      cyclonedx: 28, ## EE-specific
      requirements_v2: 29 ## EE-specific
    }

    # `file_location` indicates where actual files are stored.
    # Ideally, actual files should be stored in the same directory, and use the same
    # convention to generate its path. However, sometimes we can't do so due to backward-compatibility.
    #
    # legacy_path ... The actual file is stored at a path consists of a timestamp
    #                 and raw project/model IDs. Those rows were migrated from
    #                 `ci_builds.artifacts_file` and `ci_builds.artifacts_metadata`
    # hashed_path ... The actual file is stored at a path consists of a SHA2 based on the project ID.
    #                 This is the default value.
    enum file_location: {
      legacy_path: 1,
      hashed_path: 2
    }

    def validate_file_format!
      unless TYPE_AND_FORMAT_PAIRS[self.file_type&.to_sym] == self.file_format&.to_sym
        errors.add(:base, _('Invalid file format with specified file type'))
      end
    end

    def self.of_report_type(report_type)
      file_types = file_types_for_report(report_type)

      with_file_types(file_types)
    end

    def self.file_types_for_report(report_type)
      REPORT_FILE_TYPES.fetch(report_type) { raise ArgumentError, "Unrecognized report type: #{report_type}" }
    end

    def self.associated_file_types_for(file_type)
      return unless file_types.include?(file_type)

      [file_type]
    end

    def self.erasable_file_types
      self.file_types.keys - NON_ERASABLE_FILE_TYPES
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
      expire_at.present? && expire_at < Time.current
    end

    def expiring?
      expire_at.present? && expire_at > Time.current
    end

    def expire_in
      expire_at - Time.current if expire_at
    end

    def expire_in=(value)
      self.expire_at =
        if value
          ::Gitlab::Ci::Build::DurationParser.new(value).seconds_from_now
        end
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
      {
        file_store: file_store,
        store_dir: file.store_dir.to_s,
        file: file_identifier,
        pick_up_at: pick_up_at || expire_at || Time.current
      }
    end

    def store_after_commit?
      strong_memoize(:store_after_commit) do
        trace? && JobArtifactUploader.direct_upload_enabled?
      end
    end

    def public_access?
      return true unless Feature.enabled?(:non_public_artifacts, type: :development)

      public_accessibility?
    end

    private

    def store_file_in_transaction!
      store_file_now! if saved_change_to_file?

      file_stored_in_transaction_hooks
    end

    def store_file_after_transaction!
      store_file_now! if previous_changes.key?(:file)

      file_stored_after_transaction_hooks
    end

    # method overriden in EE
    def file_stored_after_transaction_hooks
    end

    # method overriden in EE
    def file_stored_in_transaction_hooks
    end

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
