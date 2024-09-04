# frozen_string_literal: true

module API
  module Concerns
    module VirtualRegistries
      module Packages
        module Endpoint
          extend ActiveSupport::Concern

          NO_BROWSER_EXECUTION_RESPONSE_HEADERS = { 'Content-Security-Policy' => "default-src 'none'" }.freeze
          MAJOR_BROWSERS = %i[webkit firefox ie edge opera chrome].freeze
          WEB_BROWSER_ERROR_MESSAGE = 'This endpoint is not meant to be accessed by a web browser.'
          UPSTREAM_GID_HEADER = 'X-Gitlab-Virtual-Registry-Upstream-Global-Id'

          included do
            helpers do
              def require_non_web_browser!
                browser = ::Browser.new(request.user_agent)
                bad_request!(WEB_BROWSER_ERROR_MESSAGE) if MAJOR_BROWSERS.any? { |b| browser.method(:"#{b}?").call }
              end

              def send_successful_response_from(service_response:)
                action, action_params = service_response.to_h.values_at(:action, :action_params)
                case action
                when :workhorse_upload_url
                  workhorse_upload_url(**action_params.slice(:url, :upstream))
                end
              end

              def send_error_response_from!(service_response:)
                case service_response.reason
                when :unauthorized
                  unauthorized!
                when :file_not_found_on_upstreams
                  not_found!(service_response.message)
                else
                  bad_request!(service_response.message)
                end
              end

              def workhorse_upload_url(url:, upstream:)
                send_workhorse_headers(
                  Gitlab::Workhorse.send_dependency(
                    upstream.headers,
                    url,
                    response_headers: NO_BROWSER_EXECUTION_RESPONSE_HEADERS,
                    upload_config: { headers: { UPSTREAM_GID_HEADER => upstream.to_global_id.to_s } }
                  )
                )
              end

              def send_workhorse_headers(headers)
                header(*headers)
                env['api.format'] = :binary
                content_type 'application/octet-stream'
                status :ok
                body ''
              end
            end

            after_validation do
              require_non_web_browser!
            end
          end
        end
      end
    end
  end
end
