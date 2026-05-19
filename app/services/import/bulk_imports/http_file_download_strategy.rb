# frozen_string_literal: true

module Import
  module BulkImports
    class HttpFileDownloadStrategy < FileDownloadStrategy
      LAST_CHUNK_CONTEXT_CHAR_LIMIT = 200

      # @param context [BulkImports::Context] Context object containing import configuration detail
      # @param relative_url [String] Relative URL to download the file from.
      # @param allowed_content_types [Array<String>] Allowed file content types
      def initialize(
        context:,
        relative_url:,
        allowed_content_types: DEFAULT_ALLOWED_CONTENT_TYPES)
        @context = context
        @relative_url = relative_url
        @allowed_content_types = allowed_content_types
        @remote_content_validated = false
      end

      def validate!
        validate_url!(http_client.resource_url(relative_url))
      end

      private

      attr_reader :context, :relative_url, :allowed_content_types, :response_headers, :response_code

      def perform_download(filepath)
        bytes_downloaded = 0

        File.open(filepath, 'wb') do |file|
          http_client.stream(relative_url) do |chunk|
            next if bytes_downloaded == 0 && [301, 302, 303, 307, 308].include?(chunk.code)

            if ::BulkImports::NetworkError::RETRIABLE_HTTP_CODES.include?(chunk.code)
              raise ::BulkImports::NetworkError.new(
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

          log_oversized_file(bytes_downloaded, filepath)
        end
      rescue StandardError => e
        FileUtils.rm_f(filepath)

        raise e
      end

      def log_error_params
        {
          response_code: response_code,
          response_headers: response_headers,
          last_chunk_context: last_chunk_context
        }
      end

      def log_oversized_file(size, filepath)
        return unless application_file_size_limit > 0 && size.to_i > application_file_size_limit

        logger.info(
          message: 'File size allowed to exceed download file size limit',
          filename: File.basename(filepath),
          bulk_import_id: context.bulk_import_id,
          download_file_size: size,
          download_file_size_limit: application_file_size_limit
        )
      end

      def http_client
        @http_client ||= ::BulkImports::Clients::HTTP.new(
          url: context.configuration.url,
          token: context.configuration.access_token
        )
      end

      def validate_content_type
        content_type = response_headers['content-type']

        return if content_type.present? && allowed_content_types.include?(content_type)

        log_and_raise_error('Invalid content type')
      end

      def file_size_limit
        @limit ||= context.override_file_size_limit? ? 0 : application_file_size_limit
      end

      def application_file_size_limit
        @app_limit ||= ::Gitlab::CurrentSettings.current_application_settings
          .bulk_import_max_download_file_size
          .megabytes
      end

      # Before logging, we truncate the context to a reasonable length and scrub
      # any non-printable characters.
      def last_chunk_context
        @last_chunk_context.to_s.truncate(LAST_CHUNK_CONTEXT_CHAR_LIMIT).force_encoding('utf-8').scrub
      end
    end
  end
end
