module Gitlab
  module Geo
    class FileTransfer < Transfer
      def initialize(file_type, upload)
        @file_type = file_type
        @file_id = upload.id
        @filename = upload.absolute_path
        @request_data = build_request_data(upload)
      rescue ObjectStorage::RemoteStoreError
        Rails.logger.warn "Cannot transfer a remote object."
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
