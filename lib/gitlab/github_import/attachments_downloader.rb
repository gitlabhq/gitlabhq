# frozen_string_literal: true

module Gitlab
  module GithubImport
    class AttachmentsDownloader
      include ::Gitlab::ImportExport::CommandLineUtil
      include ::BulkImports::FileDownloads::FilenameFetch
      include ::BulkImports::FileDownloads::Validations

      DownloadError = Class.new(StandardError)
      NotRetriableError = Class.new(StandardError)

      FILENAME_SIZE_LIMIT = 255 # chars before the extension
      DEFAULT_FILE_SIZE_LIMIT = Gitlab::CurrentSettings.max_attachment_size.megabytes
      TMP_DIR = File.join(Dir.tmpdir, 'github_attachments').freeze
      SUPPORTED_VIDEO_MEDIA_TYPES = %w[mov mp4 webm].freeze
      ALLOWED_FILENAME_CHARACTERS = /[^a-zA-Z0-9\-_.]/

      REDIRECT_STATUS_CODES = [301, 302, 303, 307, 308].freeze
      NON_RETRIABLE_ERROR_CODES = [403, 404, 410].freeze
      SUCCESS_STATUS_CODE = 200
      RATE_LIMIT_STATUS_CODES = [403, 429].freeze # GitHub sometimes returns rate limit responses as 403s
      RATE_LIMIT_DEFAULT_RESET_IN = 120

      attr_reader :file_url, :filename, :file_size_limit, :options, :web_endpoint

      def initialize(
        file_url, options: {}, file_size_limit: DEFAULT_FILE_SIZE_LIMIT,
        web_endpoint: ::Octokit::Default.web_endpoint)
        @file_url = file_url
        @options = options
        @file_size_limit = file_size_limit
        @web_endpoint = web_endpoint

        filename = URI(file_url).path.split('/').last
        filename = CGI.unescape(filename) # Decode URL-encoded characters

        # Check for path traversal before sanitization
        Gitlab::PathTraversal.check_path_traversal!(File.join(TMP_DIR, filename))

        filename = sanitize_filename(filename)
        @filename = ensure_filename_size(filename)
      end

      def perform
        validate_filepath

        download_url = get_assets_download_redirection_url

        # skip download for GHE server urls that redirect to a login url
        return file_url if download_url.include?("login?return_to=")

        parsed_file_name = File.basename(URI.parse(download_url).path)
        parsed_file_name = sanitize_filename(parsed_file_name)

        # if the file has a video filetype extension, we update both the @filename and @filepath with the filetype ext.
        if parsed_file_name.end_with?(*SUPPORTED_VIDEO_MEDIA_TYPES.map { |ext| ".#{ext}" })
          @filename = ensure_filename_size(parsed_file_name)
          add_extension_to_file_path(filename)
        end

        file = download_from(download_url)

        validate_symlink
        file
      end

      def delete
        FileUtils.rm_rf File.dirname(filepath)
      end

      private

      def sanitize_filename(filename)
        # Replace any character that's not alphanumeric, hyphen, underscore, or dot
        sanitized = filename.gsub(ALLOWED_FILENAME_CHARACTERS, '_')
        # Remove leading dots to prevent hidden files
        sanitized = sanitized.sub(/^\.+/, '')
        # Provide fallback if empty
        sanitized.empty? ? 'attachment' : sanitized
      end

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
        response = ::Import::Clients::HTTP.get(file_url, options)

        raise_rate_limit_error(response) if rate_limited?(response)

        if response.redirection?
          response.headers[:location]
        else
          file_url
        end
      end

      def github_assets_url_regex
        %r{#{Regexp.escape(web_endpoint)}/.*/(assets|files)/}
      end

      def download_from(url)
        file = File.open(filepath, 'wb')

        Gitlab::HTTP.perform_request(Net::HTTP::Get, url, stream_body: true) do |chunk|
          next if REDIRECT_STATUS_CODES.include?(chunk.code)

          raise_rate_limit_error(chunk) if rate_limited?(chunk)

          if NON_RETRIABLE_ERROR_CODES.include?(chunk.code)
            raise NotRetriableError, "Error downloading file from #{url}. Error code: #{chunk.code}"
          end

          if chunk.code != SUCCESS_STATUS_CODE
            raise DownloadError, "Error downloading file from #{url}. Error code: #{chunk.code}"
          end

          file.write(chunk)
          validate_size!(file.size)
        rescue AttachmentsDownloader::NotRetriableError, AttachmentsDownloader::DownloadError,
          Gitlab::GithubImport::RateLimitError
          delete
          raise
        end

        file
      end

      def rate_limited?(response)
        RATE_LIMIT_STATUS_CODES.include?(response.code)
      end

      def raise_rate_limit_error(response)
        # HTTParty::Response (redirect check) uses headers method with symbol keys
        # HTTParty::ResponseFragment (streaming) uses http_response which is Net::HTTPResponse
        retry_after = if response.respond_to?(:headers)
                        response.headers&.[](:'retry-after')
                      else
                        response.http_response&.[]('retry-after')
                      end

        return if retry_after.nil? && response.code == 403

        reset_in = retry_after.to_i
        reset_in = RATE_LIMIT_DEFAULT_RESET_IN if reset_in == 0

        raise RateLimitError.new("Rate limit exceeded. Response code: #{response.code}", reset_in)
      end

      def filepath
        @filepath ||= begin
          dir = File.join(TMP_DIR, SecureRandom.uuid)
          mkdir_p dir
          File.join(dir, filename)
        end
      end

      def add_extension_to_file_path(filename)
        @filepath = "#{filepath}#{File.extname(filename)}"
      end
    end
  end
end
