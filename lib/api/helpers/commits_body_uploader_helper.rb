# frozen_string_literal: true

module API
  module Helpers
    module CommitsBodyUploaderHelper
      def workhorse_authorize_commits_body_upload!
        require_gitlab_workhorse!

        yield if block_given?

        status 200
        content_type Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE

        ::Repositories::CommitsUploader.workhorse_authorize
      end

      def file_params_from_body_upload
        file_path = params['file.path']
        bad_request!('local file not present') unless File.exist?(file_path)

        check_large_request_rate_limit!(params['file.size'])

        media_type = Rack::MediaType.type(params['Content-Type'])

        if media_type == 'multipart/form-data'
          env = {
            'CONTENT_TYPE' => params['Content-Type'],
            'CONTENT_LENGTH' => params['file.size'],
            'rack.input' => File.open(file_path),
            # This endpoint does not support form encoded file uploads. Rack::Multipart creates a tempfile when
            # it encounters a file upload. We do not want it to create tempfiles as they are not guaranteed to be
            # cleaned up.
            Rack::RACK_MULTIPART_TEMPFILE_FACTORY => ->(_, _) do
              bad_request!('This endpoint does not support form encoded file uploads')
            end
          }

          Rack::Multipart.parse_multipart(env).deep_symbolize_keys!
        elsif media_type == 'application/x-www-form-urlencoded'
          begin
            Rack::Utils.parse_nested_query(File.read(file_path)).deep_symbolize_keys!
          rescue Rack::QueryParser::QueryLimitError => e
            bad_request!("Invalid form data exceeded query limit: #{e.message}")
          rescue Rack::QueryParser::ParameterTypeError => e
            bad_request!("Invalid parameter type: #{e.message}")
          rescue Rack::QueryParser::InvalidParameterError => e
            bad_request!("Invalid parameter: #{e.message}")
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
    end
  end
end
