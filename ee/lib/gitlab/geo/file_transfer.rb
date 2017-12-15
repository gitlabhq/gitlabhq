module Gitlab
  module Geo
    class FileTransfer < Transfer
      def initialize(file_type, upload)
        uploader = upload.uploader.constantize

        @file_type = file_type
        @file_id = upload.id
        @filename = uploader.absolute_path(upload)
        @request_data = build_request_data(upload)
      end

      private

      def build_request_data(upload)
        {
          id: upload.model_id,
          type: upload.model_type,
          checksum: upload.checksum
        }
      end
    end
  end
end
