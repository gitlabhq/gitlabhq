# frozen_string_literal: true

module API
  module Helpers
    module CommitsBodyUploaderHelper
      def workhorse_authorize_commits_body_upload!
        require_gitlab_workhorse!

        # Authenticate before Workhorse buffers the request body to disk.
        authenticate!

        yield if block_given?

        status 200
        content_type Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE

        ::Repositories::CommitsUploader.workhorse_authorize
      end

      def file_params_from_body_upload
        # Trust only middleware-finalized upload metadata for the file path and size,
        # never the raw `file.path` or `file.size` parameters.
        uploaded_file = params[:file]
        bad_request!('file is invalid') unless uploaded_file.is_a?(::UploadedFile)

        file_path = uploaded_file.path
        bad_request!('local file not present') unless file_path.present? && File.exist?(file_path)

        check_large_request_rate_limit!(uploaded_file.size)

        media_type = Rack::MediaType.type(params['Content-Type'])

        if media_type == 'multipart/form-data'
          uploaded_file.rewind

          env = {
            'CONTENT_TYPE' => params['Content-Type'],
            'CONTENT_LENGTH' => uploaded_file.size.to_s,
            'rack.input' => uploaded_file,
            # This endpoint does not support form encoded file uploads. Rack::Multipart creates a tempfile when
            # it encounters a file upload. We do not want it to create tempfiles as they are not guaranteed to be
            # cleaned up.
            Rack::RACK_MULTIPART_TEMPFILE_FACTORY => ->(_, _) do
              bad_request!('This endpoint does not support form encoded file uploads')
            end
          }

          Gitlab::Repositories::LargeMultipartParser.parse_multipart(env).deep_symbolize_keys!
        elsif media_type == 'application/x-www-form-urlencoded'
          begin
            Rack::Utils.parse_nested_query(File.read(file_path)).deep_symbolize_keys!
          rescue Rack::QueryParser::QueryLimitError
            bad_request!('Invalid form data exceeded query limit')
          rescue Rack::QueryParser::ParameterTypeError
            bad_request!('Invalid parameter type')
          rescue Rack::QueryParser::InvalidParameterError
            bad_request!('Invalid parameter')
          end
        elsif media_type.nil? || media_type == 'application/json'
          Oj.load_file(file_path, symbol_keys: true)
        else
          bad_request!("Unsupported Content-Type: #{media_type}")
        end
      end

      def check_large_request_rate_limit!(file_size_bytes)
        file_size_bytes = file_size_bytes&.to_i

        if file_size_bytes.blank? || file_size_bytes > ::Repositories::CommitsUploader::MAX_RATE_LIMITED_REQUEST_SIZE
          check_rate_limit!(:user_large_commit_request, scope: current_user)
        end
      end

      # Validates that a parameter value is a string if present.
      # Does not validate presence - use existing blank? checks for that.
      def validate_string_param!(params, key, prefix: nil)
        return unless params.key?(key)

        value = params[key]
        return if value.nil?
        return if value.is_a?(String)

        param_name = prefix ? "#{prefix}[#{key}]" : key.to_s
        bad_request!("#{param_name} must be a string")
      end
    end
  end
end
