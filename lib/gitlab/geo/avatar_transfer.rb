module Gitlab
  module Geo
    class AvatarTransfer < Transfer
      def initialize(upload)
        @file_type = :avatar
        @file_id = upload.id
        @filename = upload.path
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
