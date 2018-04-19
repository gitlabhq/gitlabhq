module Ci
  class JobArtifact < ActiveRecord::Base
    prepend EE::Ci::JobArtifact

    include AfterCommitQueue
    include ObjectStorage::BackgroundMove
    extend Gitlab::Ci::Model

    belongs_to :project
    belongs_to :job, class_name: "Ci::Build", foreign_key: :job_id

    mount_uploader :file, JobArtifactUploader

    before_save :set_size, if: :file_changed?
    after_save :update_project_statistics_after_save, if: :size_changed?
    after_destroy :update_project_statistics_after_destroy, unless: :project_destroyed?

    after_save :update_file_store

    scope :with_files_stored_locally, -> { where(file_store: [nil, ::JobArtifactUploader::Store::LOCAL]) }
    scope :with_files_stored_remotely, -> { where(file_store: ::JobArtifactUploader::Store::REMOTE) }

    delegate :exists?, :open, to: :file

    enum file_type: {
      archive: 1,
      metadata: 2,
      trace: 3
    }

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

    private

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
