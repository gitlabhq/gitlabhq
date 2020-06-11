# frozen_string_literal: true

module Ci
  class JobArtifact < ApplicationRecord
    include AfterCommitQueue
    include ObjectStorage::BackgroundMove
    include UpdateProjectStatistics
    include UsageStatistics
    include Sortable
    extend Gitlab::Ci::Model

    NotSupportedAdapterError = Class.new(StandardError)

    TEST_REPORT_FILE_TYPES = %w[junit].freeze
    COVERAGE_REPORT_FILE_TYPES = %w[cobertura].freeze
    ACCESSIBILITY_REPORT_FILE_TYPES = %w[accessibility].freeze
    NON_ERASABLE_FILE_TYPES = %w[trace].freeze
    TERRAFORM_REPORT_FILE_TYPES = %w[terraform].freeze
    UNSUPPORTED_FILE_TYPES = %i[license_management].freeze
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
      dast: 'gl-dast-report.json',
      license_management: 'gl-license-management-report.json',
      license_scanning: 'gl-license-scanning-report.json',
      performance: 'performance.json',
      metrics: 'metrics.txt',
      lsif: 'lsif.json',
      dotenv: '.env',
      cobertura: 'cobertura-coverage.xml',
      terraform: 'tfplan.json',
      cluster_applications: 'gl-cluster-applications.json',
      requirements: 'requirements.json'
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
      cluster_applications: :gzip,
      lsif: :zip,

      # All these file formats use `raw` as we need to store them uncompressed
      # for Frontend to fetch the files and do analysis
      # When they will be only used by backend, they can be `gzipped`.
      accessibility: :raw,
      codequality: :raw,
      sast: :raw,
      secret_detection: :raw,
      dependency_scanning: :raw,
      container_scanning: :raw,
      dast: :raw,
      license_management: :raw,
      license_scanning: :raw,
      performance: :raw,
      terraform: :raw,
      requirements: :raw
    }.freeze

    DOWNLOADABLE_TYPES = %w[
      accessibility
      archive
      cobertura
      codequality
      container_scanning
      dast
      dependency_scanning
      dotenv
      junit
      license_management
      license_scanning
      lsif
      metrics
      performance
      sast
      secret_detection
      requirements
    ].freeze

    TYPE_AND_FORMAT_PAIRS = INTERNAL_TYPES.merge(REPORT_TYPES).freeze

    # This is required since we cannot add a default to the database
    # https://gitlab.com/gitlab-org/gitlab/-/issues/215418
    attribute :locked, :boolean, default: false

    belongs_to :project
    belongs_to :job, class_name: "Ci::Build", foreign_key: :job_id

    mount_uploader :file, JobArtifactUploader

    validates :file_format, presence: true, unless: :trace?, on: :create
    validate :validate_supported_file_format!, on: :create
    validate :validate_file_format!, unless: :trace?, on: :create
    before_save :set_size, if: :file_changed?

    update_project_statistics project_statistics_name: :build_artifacts_size

    after_save :update_file_store, if: :saved_change_to_file?

    scope :not_expired, -> { where('expire_at IS NULL OR expire_at > ?', Time.current) }
    scope :with_files_stored_locally, -> { where(file_store: [nil, ::JobArtifactUploader::Store::LOCAL]) }
    scope :with_files_stored_remotely, -> { where(file_store: ::JobArtifactUploader::Store::REMOTE) }
    scope :for_sha, ->(sha, project_id) { joins(job: :pipeline).where(ci_pipelines: { sha: sha, project_id: project_id }) }
    scope :for_ref, ->(ref, project_id) { joins(job: :pipeline).where(ci_pipelines: { ref: ref, project_id: project_id }) }
    scope :for_job_name, ->(name) { joins(:job).where(ci_builds: { name: name }) }

    scope :with_file_types, -> (file_types) do
      types = self.file_types.select { |file_type| file_types.include?(file_type) }.values

      where(file_type: types)
    end

    scope :with_reports, -> do
      with_file_types(REPORT_TYPES.keys.map(&:to_s))
    end

    scope :test_reports, -> do
      with_file_types(TEST_REPORT_FILE_TYPES)
    end

    scope :accessibility_reports, -> do
      with_file_types(ACCESSIBILITY_REPORT_FILE_TYPES)
    end

    scope :coverage_reports, -> do
      with_file_types(COVERAGE_REPORT_FILE_TYPES)
    end

    scope :terraform_reports, -> do
      with_file_types(TERRAFORM_REPORT_FILE_TYPES)
    end

    scope :erasable, -> do
      types = self.file_types.reject { |file_type| NON_ERASABLE_FILE_TYPES.include?(file_type) }.values

      where(file_type: types)
    end

    scope :expired, -> (limit) { where('expire_at < ?', Time.current).limit(limit) }
    scope :downloadable, -> { where(file_type: DOWNLOADABLE_TYPES) }
    scope :locked, -> { where(locked: true) }
    scope :unlocked, -> { where(locked: [false, nil]) }

    scope :scoped_project, -> { where('ci_job_artifacts.project_id = projects.id') }

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
      license_management: 10, ## EE-specific
      license_scanning: 101, ## EE-specific till 13.0
      performance: 11, ## EE-specific
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
      requirements: 22 ## EE-specific
    }

    enum file_format: {
      raw: 1,
      zip: 2,
      gzip: 3
    }, _suffix: true

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

    FILE_FORMAT_ADAPTERS = {
      gzip: Gitlab::Ci::Build::Artifacts::Adapters::GzipStream,
      raw: Gitlab::Ci::Build::Artifacts::Adapters::RawStream
    }.freeze

    def validate_supported_file_format!
      return if Feature.disabled?(:drop_license_management_artifact, project, default_enabled: true)

      if UNSUPPORTED_FILE_TYPES.include?(self.file_type&.to_sym)
        errors.add(:base, _("File format is no longer supported"))
      end
    end

    def validate_file_format!
      unless TYPE_AND_FORMAT_PAIRS[self.file_type&.to_sym] == self.file_format&.to_sym
        errors.add(:base, _('Invalid file format with specified file type'))
      end
    end

    def update_file_store
      # The file.object_store is set during `uploader.store!`
      # which happens after object is inserted/updated
      self.update_column(:file_store, file.object_store)
    end

    def self.total_size
      self.sum(:size)
    end

    def self.artifacts_size_for(project)
      self.where(project: project).sum(:size)
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
          ChronicDuration.parse(value)&.seconds&.from_now
        end
    end

    def each_blob(&blk)
      unless file_format_adapter_class
        raise NotSupportedAdapterError, 'This file format requires a dedicated adapter'
      end

      file.open do |stream|
        file_format_adapter_class.new(stream).each_blob(&blk)
      end
    end

    def self.archived_trace_exists_for?(job_id)
      where(job_id: job_id).trace.take&.file&.file&.exists?
    end

    private

    def file_format_adapter_class
      FILE_FORMAT_ADAPTERS[file_format.to_sym]
    end

    def set_size
      self.size = file.size
    end

    def project_destroyed?
      # Use job.project to avoid extra DB query for project
      job.project.pending_delete?
    end
  end
end

Ci::JobArtifact.prepend_if_ee('EE::Ci::JobArtifact')
