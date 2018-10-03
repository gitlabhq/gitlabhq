module Geo
  class JobArtifactDeletedEventStore < EventStore
    extend ::Gitlab::Utils::Override

    self.event_type = :job_artifact_deleted_event

    attr_reader :job_artifact

    def initialize(job_artifact)
      @job_artifact = job_artifact
    end

    private

    def build_event
      Geo::JobArtifactDeletedEvent.new(
        job_artifact: job_artifact,
        file_path: relative_file_path
      )
    end

    def relative_file_path
      job_artifact.file.relative_path if job_artifact.file.present?
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
