module Gitlab
  module Geo
    class AvatarDownloader < FileDownloader
      def execute
        upload = Upload.find_by_id(object_db_id)
        return unless upload.present?

        transfer = ::Gitlab::Geo::AvatarTransfer.new(upload)
        transfer.download_from_primary
      end
    end
  end
end
