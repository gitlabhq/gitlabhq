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
      DEFAULT_FILE_SIZE_LIMIT = 25.megabytes
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
        validate_content_length
        validate_filepath

        redirection_url = get_assets_download_redirection_url
        file = download_from(redirection_url)

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

      # Github /assets redirection link will redirect to aws which has its own authorization.
      # Keeping our bearer token will cause request rejection
      # eg. Only one auth mechanism allowed; only the X-Amz-Algorithm query parameter,
      # Signature query string parameter or the Authorization header should be specified.
      def get_assets_download_redirection_url
        return file_url unless file_url.starts_with?(github_assets_url_regex)

        options[:follow_redirects] = false
        response = Gitlab::HTTP.perform_request(Net::HTTP::Get, file_url, options)
        raise_error("expected a redirect response, got #{response.code}") unless response.redirection?

        redirection_url = response.headers[:location]
        filename = URI.parse(redirection_url).path

        unless Gitlab::GithubImport::Markdown::Attachment::MEDIA_TYPES.any? { |type| filename.ends_with?(type) }
          raise UnsupportedAttachmentError
        end

        redirection_url
      end

      def github_assets_url_regex
        %r{#{Regexp.escape(::Gitlab::GithubImport::MarkdownText.github_url)}/.*/assets/}
      end

      def download_from(url)
        file = File.open(filepath, 'wb')
        Gitlab::HTTP.perform_request(Net::HTTP::Get, url, stream_body: true) { |batch| file.write(batch) }
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
