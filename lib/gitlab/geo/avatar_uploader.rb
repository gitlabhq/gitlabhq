module Gitlab
  module Geo
    class AvatarUploader < FileUploader
      def execute
        upload = Upload.find_by_id(object_db_id)

        return error unless upload.present?
        return error unless valid?(upload)

        unless upload.model.avatar&.exists?
          return error("#{upload.model_type} does not have a avatar")
        end

        success(upload.model.avatar)
      end

      private

      def valid?(upload)
        message[:id] == upload.model_id && message[:type] == upload.model_type &&
          message[:checksum] == upload.checksum
      end
    end
  end
end
