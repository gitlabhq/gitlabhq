# frozen_string_literal: true

module Gitlab
  module GithubImport
    class AttachmentsDownloader
      include ::Gitlab::ImportExport::CommandLineUtil
      include ::BulkImports::FileDownloads::FilenameFetch
      include ::BulkImports::FileDownloads::Validations

      DownloadError = Class.new(StandardError)
      UnsupportedAttachmentError = Class.new(StandardError)

      FILENAME_SIZE_LIMIT = 255 # chars before the extension
      DEFAULT_FILE_SIZE_LIMIT = Gitlab::CurrentSettings.max_attachment_size.megabytes
      TMP_DIR = File.join(Dir.tmpdir, 'github_attachments').freeze

      attr_reader :file_url, :filename, :file_size_limit, :options

      def initialize(file_url, options: {}, file_size_limit: DEFAULT_FILE_SIZE_LIMIT)
        @file_url = file_url
        @options = options
        @file_size_limit = file_size_limit

        filename = URI(file_url).path.split('/').last
        @filename = ensure_filename_size(filename)
      end

      def perform
        validate_filepath

        download_url = get_assets_download_redirection_url
        file = download_from(download_url)

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

      # Github /assets redirection link will redirect to aws which has its own authorization.
      # Keeping our bearer token will cause request rejection
      # eg. Only one auth mechanism allowed; only the X-Amz-Algorithm query parameter,
      # Signature query string parameter or the Authorization header should be specified.
      def get_assets_download_redirection_url
        return file_url unless file_url.starts_with?(github_assets_url_regex)

        options[:follow_redirects] = false
        response = Gitlab::HTTP.perform_request(Net::HTTP::Get, file_url, options)

        download_url = if response.redirection?
                         response.headers[:location]
                       else
                         file_url
                       end

        file_type_valid?(URI.parse(download_url).path)

        download_url
      end

      def github_assets_url_regex
        %r{#{Regexp.escape(::Gitlab::GithubImport::MarkdownText.github_url)}/.*/assets/}
      end

      def download_from(url)
        file = File.open(filepath, 'wb')

        Gitlab::HTTP.perform_request(Net::HTTP::Get, url, stream_body: true) do |chunk|
          next if [301, 302, 303, 307, 308].include?(chunk.code)

          raise DownloadError, "Error downloading file from #{url}. Error code: #{chunk.code}" if chunk.code != 200

          file.write(chunk)
          validate_size!(file.size)
        rescue Gitlab::GithubImport::AttachmentsDownloader::DownloadError
          delete
          raise
        end

        file
      end

      def filepath
        @filepath ||= begin
          dir = File.join(TMP_DIR, SecureRandom.uuid)
          mkdir_p dir
          File.join(dir, filename)
        end
      end

      def file_type_valid?(file_url)
        return if Gitlab::GithubImport::Markdown::Attachment::MEDIA_TYPES.any? { |type| file_url.ends_with?(type) }

        raise UnsupportedAttachmentError
      end
    end
  end
end
