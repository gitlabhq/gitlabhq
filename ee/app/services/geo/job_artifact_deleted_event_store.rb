module Geo
  class JobArtifactDeletedEventStore < EventStore
    self.event_type = :job_artifact_deleted_event

    attr_reader :job_artifact

    def initialize(job_artifact)
      @job_artifact = job_artifact
    end

    def create
      return unless job_artifact.local_store?

      super
    end

    private

    def build_event
      Geo::JobArtifactDeletedEvent.new(
        job_artifact: job_artifact,
        file_path: relative_file_path
      )
    end

    def local_store_path
      Pathname.new(JobArtifactUploader.local_store_path)
    end

    def relative_file_path
      return unless job_artifact.file.present?

      Pathname.new(job_artifact.file.path).relative_path_from(local_store_path)
    end

    # This is called by ProjectLogHelpers to build json log with context info
    #
    # @see ::Gitlab::Geo::ProjectLogHelpers
    def base_log_data(message)
      {
        class: self.class.name,
        job_artifact_id: job_artifact.id,
        file_path: job_artifact.file.path,
        message: message
      }
    end
  end
end
