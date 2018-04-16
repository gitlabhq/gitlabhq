module Gitlab
  module Geo
    # This class is responsible for:
    #   * Finding an Upload record
    #   * Returning the necessary response data to send the file back
    #
    # TODO: Rearrange things so this class not inherited by JobArtifactUploader and LfsUploader
    # Maybe rename it so it doesn't seem generic. It only works with Upload records.
    class FileUploader
      include LogHelpers

      FILE_NOT_FOUND_GEO_CODE = 'FILE_NOT_FOUND'.freeze

      attr_reader :object_db_id, :message

      def initialize(object_db_id, message)
        @object_db_id = object_db_id
        @message = message
      end

      def execute
        recorded_file = Upload.find_by(id: object_db_id)

        return error('Upload not found') unless recorded_file
        return file_not_found(recorded_file) unless recorded_file.exist?
        return error('Upload not found') unless valid?(recorded_file)

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

      def error(message)
        { code: :not_found, message: message }
      end

      # A 404 implies the client made a mistake requesting that resource.
      # In this case, we know that the resource should exist, so it is a 500 server error.
      # We send a special "geo_code" so the secondary can mark the file as synced.
      def file_not_found(resource)
        {
          code: :not_found,
          geo_code: FILE_NOT_FOUND_GEO_CODE,
          message: "#{resource.class.name} ##{resource.id} file not found"
        }
      end
    end
  end
end
