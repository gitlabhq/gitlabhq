module Gitlab
  module Geo
    # This class is responsible for:
    #   * Finding an Upload record
    #   * Requesting and downloading the Upload's file from the primary
    #   * Returning a detailed Result
    #
    # TODO: Rearrange things so this class not inherited by JobArtifactDownloader and LfsDownloader
    # Maybe rename it so it doesn't seem generic. It only works with Upload records.
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
        return fail_before_transfer unless upload.present?

        transfer = ::Gitlab::Geo::FileTransfer.new(object_type.to_sym, upload)
        Result.from_transfer_result(transfer.download_from_primary)
      end

      class Result
        attr_reader :success, :bytes_downloaded, :primary_missing_file, :failed_before_transfer

        def self.from_transfer_result(transfer_result)
          Result.new(success: transfer_result.success,
                     primary_missing_file: transfer_result.primary_missing_file,
                     bytes_downloaded: transfer_result.bytes_downloaded)
        end

        def initialize(success:, bytes_downloaded:, primary_missing_file: false, failed_before_transfer: false)
          @success = success
          @bytes_downloaded = bytes_downloaded
          @primary_missing_file = primary_missing_file
          @failed_before_transfer = failed_before_transfer
        end
      end

      private

      def fail_before_transfer
        Result.new(success: false, bytes_downloaded: 0, failed_before_transfer: true)
      end
    end
  end
end
