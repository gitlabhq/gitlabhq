# frozen_string_literal: true

module Gitlab
  module ImportExport
    module AfterExportStrategies
      class WebUploadStrategy < BaseAfterExportStrategy
        PUT_METHOD = 'PUT'
        POST_METHOD = 'POST'
        INVALID_HTTP_METHOD = 'invalid. Only PUT and POST methods allowed.'

        validates :url, addressable_url: true

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
        end

        def handle_response_error(response)
          unless response.success?
            raise StrategyError, "Error uploading the project. Code #{response.code}: #{response.message}"
          end
        end

        def delete_export?
          false
        end

        private

        def send_file
          Gitlab::HTTP.public_send(http_method.downcase, url, send_file_options) # rubocop:disable GitlabSecurity/PublicSend
        ensure
          export_file.close if export_file
        end

        def export_file
          project.export_file.open
        end

        def send_file_options
          {
            body_stream: export_file,
            headers: headers
          }
        end

        def headers
          {
            'Content-Type' => 'application/gzip',
            'Content-Length' => export_size.to_s
          }
        end

        def export_size
          project.export_file.file.size
        end
      end
    end
  end
end
