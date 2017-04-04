module Gitlab
  module Geo
    class FileUploader
      attr_reader :object_db_id, :message

      def initialize(object_db_id, message)
        @object_db_id = object_db_id
        @message = message
      end

      def execute
        raise NotImplementedError
      end

      private

      def success(file)
        { code: :ok, message: 'Success', file: file }
      end

      def error(message = 'File not found')
        { code: :not_found, message: message }
      end
    end
  end
end
