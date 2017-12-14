module Gitlab
  module Geo
    class FileDownloader
      attr_reader :object_type, :object_db_id

      def initialize(object_type, object_db_id)
        @object_type = object_type
        @object_db_id = object_db_id
      end

      # Executes the actual file download
      #
      # Subclasses should return the number of bytes downloaded,
      # or nil or -1 if a failure occurred.
      def execute
        upload = Upload.find_by(id: object_db_id)
        return unless upload.present?

        transfer = ::Gitlab::Geo::FileTransfer.new(object_type.to_sym, upload)
        transfer.download_from_primary
      end
    end
  end
end
