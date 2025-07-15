# frozen_string_literal: true

# File Download Service allows remote file download into tmp directory.
#
# @param context [BulkImports::Context] Context object containing url and access token
# @param relative_url [String] Relative URL to download the file from
# @param tmpdir [String] Temp directory to store downloaded file to. Must be located under `Dir.tmpdir`.
# @param allowed_content_types [Array<String>] Allowed file content types
# @param filename [String] Name of the file to download, if known. Use remote filename if none given.
module BulkImports
  class FileDownloadService
    include ::BulkImports::FileDownloads::FilenameFetch
    include ::BulkImports::FileDownloads::Validations

    ServiceError = Class.new(StandardError)

    DEFAULT_ALLOWED_CONTENT_TYPES = %w[application/gzip application/octet-stream].freeze
    LAST_CHUNK_CONTEXT_CHAR_LIMIT = 200

    def initialize(
      context:,
      relative_url:,
      tmpdir:,
      allowed_content_types: DEFAULT_ALLOWED_CONTENT_TYPES,
      filename: nil)
      @context = context
      @relative_url = relative_url
      @filename = filename
      @tmpdir = tmpdir
      @allowed_content_types = allowed_content_types
      @remote_content_validated = false
    end

    def execute
      validate_tmpdir
      validate_filepath
      validate_url

      download_file

      validate_symlink

      filepath
    end

    private

    attr_reader :context, :relative_url, :tmpdir, :allowed_content_types, :response_headers, :response_code

    def download_file
      bytes_downloaded = 0

      File.open(filepath, 'wb') do |file|
        http_client.stream(relative_url) do |chunk|
          next if bytes_downloaded == 0 && [301, 302, 303, 307, 308].include?(chunk.code)

          if BulkImports::NetworkError::RETRIABLE_HTTP_CODES.include?(chunk.code)
            raise BulkImports::NetworkError.new(
              "Error downloading file from #{relative_url}. Error code: #{chunk.code}",
              response: chunk.http_response
            )
          end

          @response_code = chunk.code
          @response_headers ||= Gitlab::HTTP::Response::Headers.new(chunk.http_response.to_hash)
          @last_chunk_context = chunk

          unless @remote_content_validated
            validate_content_type

            @remote_content_validated = true
          end

          bytes_downloaded += chunk.size

          validate_size!(bytes_downloaded)

          raise(ServiceError, "File download error #{chunk.code}") unless chunk.code == 200

          file.write(chunk)
        end

        log_oversized_file(bytes_downloaded)
      end
    rescue StandardError => e
      FileUtils.rm_f(filepath)

      raise e
    end

    def raise_error(message)
      logger.warn(
        message: message,
        response_code: response_code,
        response_headers: response_headers,
        last_chunk_context: last_chunk_context
      )

      raise ServiceError, message
    end

    def log_oversized_file(size)
      return unless application_file_size_limit > 0 && size.to_i > application_file_size_limit

      logger.info(
        message: 'File size allowed to exceed download file size limit',
        filename: filename,
        bulk_import_id: context.bulk_import_id,
        download_file_size: size,
        download_file_size_limit: application_file_size_limit
      )
    end

    def http_client
      @http_client ||= BulkImports::Clients::HTTP.new(
        url: context.configuration.url,
        token: context.configuration.access_token
      )
    end

    def allow_local_requests?
      ::Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
    end

    def validate_tmpdir
      Gitlab::PathTraversal.check_allowed_absolute_path!(tmpdir, [Dir.tmpdir])
    end

    def filepath
      @filepath ||= File.join(@tmpdir, filename)
    end

    def filename
      @filename.presence || remote_filename
    end

    def logger
      @logger ||= Logger.build
    end

    def validate_url
      ::Gitlab::HTTP_V2::UrlBlocker.validate!(
        http_client.resource_url(relative_url),
        allow_localhost: allow_local_requests?,
        allow_local_network: allow_local_requests?,
        schemes: %w[http https],
        deny_all_requests_except_allowed: ::Gitlab::CurrentSettings.deny_all_requests_except_allowed?,
        outbound_local_requests_allowlist: ::Gitlab::CurrentSettings.outbound_local_requests_whitelist) # rubocop:disable Naming/InclusiveLanguage -- existing setting
    end

    def file_size_limit
      @limit ||= context.override_file_size_limit? ? 0 : application_file_size_limit
    end

    def application_file_size_limit
      @app_limit ||= Gitlab::CurrentSettings.current_application_settings.bulk_import_max_download_file_size.megabytes
    end

    # Before logging, we truncate the context to a reasonable length and scrub
    # any non-printable characters.
    def last_chunk_context
      @last_chunk_context.to_s.truncate(LAST_CHUNK_CONTEXT_CHAR_LIMIT).force_encoding('utf-8').scrub
    end
  end
end
