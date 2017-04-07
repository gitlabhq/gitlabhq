module Gitlab
  module Geo
    class FileUploader
      attr_reader :object_db_id, :message

      def initialize(object_db_id, message)
        @object_db_id = object_db_id
        @message = message
      end

      def execute
        recorded_file = Upload.find_by(id: object_db_id)

        return error unless recorded_file&.exist?
        return error unless valid?(recorded_file)

        success(CarrierWave::SanitizedFile.new(recorded_file.absolute_path))
      end

      private

      def valid?(recorded_file)
        matches_requested_model?(recorded_file) &&
          matches_checksum?(recorded_file)
      end

      def matches_requested_model?(recorded_file)
        message[:id] == recorded_file.model_id &&
          message[:type] == recorded_file.model_type
      end

      def matches_checksum?(recorded_file)
        message[:checksum] == Upload.hexdigest(recorded_file.absolute_path)
      end

      def success(file)
        { code: :ok, message: 'Success', file: file }
      end

      def error(message = 'File not found')
        { code: :not_found, message: message }
      end
    end
  end
end
