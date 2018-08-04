# frozen_string_literal: true

module Ci
  class JobArtifact < ActiveRecord::Base
    prepend EE::Ci::JobArtifact

    include AfterCommitQueue
    include ObjectStorage::BackgroundMove
    extend Gitlab::Ci::Model

    NotSupportedAdapterError = Class.new(StandardError)

    TEST_REPORT_FILE_TYPES = %w[junit].freeze
    DEFAULT_FILE_NAMES = { junit: 'junit.xml' }.freeze
    TYPE_AND_FORMAT_PAIRS = { archive: :zip, metadata: :gzip, trace: :raw, junit: :gzip }.freeze

    belongs_to :project
    belongs_to :job, class_name: "Ci::Build", foreign_key: :job_id

    mount_uploader :file, JobArtifactUploader

    validates :file_format, presence: true, unless: :trace?, on: :create
    validate :valid_file_format?, unless: :trace?, on: :create
    before_save :set_size, if: :file_changed?
    after_save :update_project_statistics_after_save, if: :size_changed?
    after_destroy :update_project_statistics_after_destroy, unless: :project_destroyed?

    after_save :update_file_store, if: :file_changed?

    scope :with_files_stored_locally, -> { where(file_store: [nil, ::JobArtifactUploader::Store::LOCAL]) }
    scope :with_files_stored_remotely, -> { where(file_store: ::JobArtifactUploader::Store::REMOTE) }

    scope :test_reports, -> do
      types = self.file_types.select { |file_type| TEST_REPORT_FILE_TYPES.include?(file_type) }.values

      where(file_type: types)
    end

    delegate :exists?, :open, to: :file

    enum file_type: {
      archive: 1,
      metadata: 2,
      trace: 3,
      junit: 4
    }

    enum file_format: {
      raw: 1,
      zip: 2,
      gzip: 3
    }

    FILE_FORMAT_ADAPTERS = {
      gzip: Gitlab::Ci::Build::Artifacts::GzipFileAdapter
    }.freeze

    def valid_file_format?
      unless TYPE_AND_FORMAT_PAIRS[self.file_type&.to_sym] == self.file_format&.to_sym
        errors.add(:file_format, 'Invalid file format with specified file type')
      end
    end

    def update_file_store
      # The file.object_store is set during `uploader.store!`
      # which happens after object is inserted/updated
      self.update_column(:file_store, file.object_store)
    end

    def self.artifacts_size_for(project)
      self.where(project: project).sum(:size)
    end

    def local_store?
      [nil, ::JobArtifactUploader::Store::LOCAL].include?(self.file_store)
    end

    def expire_in
      expire_at - Time.now if expire_at
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

    private

    def file_format_adapter_class
      FILE_FORMAT_ADAPTERS[file_format.to_sym]
    end

    def set_size
      self.size = file.size
    end

    def update_project_statistics_after_save
      update_project_statistics(size.to_i - size_was.to_i)
    end

    def update_project_statistics_after_destroy
      update_project_statistics(-self.size)
    end

    def update_project_statistics(difference)
      ProjectStatistics.increment_statistic(project_id, :build_artifacts_size, difference)
    end

    def project_destroyed?
      # Use job.project to avoid extra DB query for project
      job.project.pending_delete?
    end
  end
end
