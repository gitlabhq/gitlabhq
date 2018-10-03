module Geo
  class UploadDeletedEventStore < EventStore
    extend ::Gitlab::Utils::Override

    self.event_type = :upload_deleted_event

    attr_reader :upload

    def initialize(upload)
      @upload = upload
    end

    private

    def build_event
      Geo::UploadDeletedEvent.new(
        upload: upload,
        file_path: upload.path,
        model_id: upload.model_id,
        model_type: upload.model_type,
        uploader: upload.uploader
      )
    end

    # This is called by ProjectLogHelpers to build json log with context info
    #
    # @see ::Gitlab::Geo::ProjectLogHelpers
    def base_log_data(message)
      {
        class: self.class.name,
        upload_id: upload.id,
        file_path: upload.path,
        model_id: upload.model_id,
        model_type: upload.model_type,
        uploader: upload.uploader,
        message: message
      }
    end
  end
end
