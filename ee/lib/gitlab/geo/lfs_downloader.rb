module Gitlab
  module Geo
    # This class is responsible for:
    #   * Finding a LfsObject record
    #   * Requesting and downloading the LfsObject's file from the primary
    #   * Returning a detailed Result
    #
    # TODO: Rearrange things so this class does not inherit FileDownloader
    class LfsDownloader < FileDownloader
      def execute
        lfs_object = LfsObject.find_by(id: object_db_id)
        return fail_before_transfer unless lfs_object.present?

        transfer = ::Gitlab::Geo::LfsTransfer.new(lfs_object)
        Result.from_transfer_result(transfer.download_from_primary)
      end
    end
  end
end
