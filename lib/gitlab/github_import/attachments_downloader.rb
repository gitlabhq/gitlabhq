# frozen_string_literal: true

module Gitlab
  module GithubImport
    class AttachmentsDownloader
      include ::Gitlab::ImportExport::CommandLineUtil
      include ::BulkImports::FileDownloads::FilenameFetch
      include ::BulkImports::FileDownloads::Validations

      DownloadError = Class.new(StandardError)

      FILENAME_SIZE_LIMIT = 255 # chars before the extension
      DEFAULT_FILE_SIZE_LIMIT = 25.megabytes
      TMP_DIR = File.join(Dir.tmpdir, 'github_attachments').freeze

      attr_reader :file_url, :filename, :file_size_limit

      def initialize(file_url, file_size_limit: DEFAULT_FILE_SIZE_LIMIT)
        @file_url = file_url
        @file_size_limit = file_size_limit

        filename = URI(file_url).path.split('/').last
        @filename = ensure_filename_size(filename)
      end

      def perform
        validate_content_length
        validate_filepath

        file = download
        validate_symlink
        file
      end

      def delete
        FileUtils.rm_rf File.dirname(filepath)
      end

      private

      def raise_error(message)
        raise DownloadError, message
      end

      def response_headers
        @response_headers ||=
          Gitlab::HTTP.perform_request(Net::HTTP::Head, file_url, {}).headers
      end

      def download
        file = File.open(filepath, 'wb')
        Gitlab::HTTP.perform_request(Net::HTTP::Get, file_url, stream_body: true) { |batch| file.write(batch) }
        file
      end

      def filepath
        @filepath ||= begin
          dir = File.join(TMP_DIR, SecureRandom.uuid)
          mkdir_p dir
          File.join(dir, filename)
        end
      end
    end
  end
end
