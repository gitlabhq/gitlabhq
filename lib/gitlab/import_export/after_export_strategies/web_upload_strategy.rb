module Gitlab
  module ImportExport
    module AfterExportStrategies
      class WebUploadStrategy < BaseAfterExportStrategy
        PUT_METHOD = 'PUT'.freeze
        POST_METHOD = 'POST'.freeze
        INVALID_HTTP_METHOD = 'invalid. Only PUT and POST methods allowed.'.freeze

        validates :url, url: true

        validate do
          unless [PUT_METHOD, POST_METHOD].include?(http_method.upcase)
            errors.add(:http_method, INVALID_HTTP_METHOD)
          end
        end

        def initialize(url:, http_method: PUT_METHOD)
          super
        end

        protected

        def strategy_execute
          handle_response_error(send_file)

          project.remove_exported_project_file
        end

        def handle_response_error(response)
          unless response.success?
            error_code = response.dig('Error', 'Code') || response.code
            error_message = response.dig('Error', 'Message') || response.message

            raise StrategyError.new("Error uploading the project. Code #{error_code}: #{error_message}")
          end
        end

        private

        def send_file
          export_file = File.open(project.export_project_path)

          Gitlab::HTTP.public_send(http_method.downcase, url, send_file_options(export_file)) # rubocop:disable GitlabSecurity/PublicSend
        ensure
          export_file.close if export_file
        end

        def send_file_options(export_file)
          {
            body_stream: export_file,
            headers: headers
          }
        end

        def headers
          { 'Content-Length' => File.size(project.export_project_path).to_s }
        end
      end
    end
  end
end
