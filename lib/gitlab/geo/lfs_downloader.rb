module Gitlab
  module Geo
    class LfsDownloader < FileDownloader
      def execute
        lfs_object = LfsObject.find_by(id: object_db_id)
        return unless lfs_object.present?

        transfer = ::Gitlab::Geo::LfsTransfer.new(lfs_object)
        transfer.download_from_primary
      end
    end
  end
end
