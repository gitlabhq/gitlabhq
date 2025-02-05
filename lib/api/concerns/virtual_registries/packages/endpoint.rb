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
          MAX_FILE_SIZE = 5.gigabytes

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
                when :download_file
                  extra_response_headers = download_file_extra_response_headers(action_params: action_params)
                  present_carrierwave_file!(
                    action_params[:file],
                    supports_direct_download: extra_response_headers.blank?,
                    content_type: action_params[:content_type],
                    content_disposition: 'inline',
                    extra_response_headers: extra_response_headers
                  )
                when :download_digest
                  content_type 'text/plain'
                  env['api.format'] = :binary # to return data as-is
                  body action_params[:digest]
                end
              end

              def send_error_response_from!(service_response:)
                case service_response.reason
                when :unauthorized
                  unauthorized!
                when :file_not_found_on_upstreams, :digest_not_found_in_cache_entries
                  not_found!(service_response.message)
                else
                  bad_request!(service_response.message)
                end
              end

              def workhorse_upload_url(url:, upstream:)
                allow_localhost = Gitlab.dev_or_test_env? ||
                  Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
                allowed_uris = ObjectStoreSettings.enabled_endpoint_uris
                send_workhorse_headers(
                  Gitlab::Workhorse.send_dependency(
                    upstream.headers,
                    url,
                    response_headers: NO_BROWSER_EXECUTION_RESPONSE_HEADERS,
                    allow_localhost: allow_localhost,
                    allowed_uris: allowed_uris,
                    ssrf_filter: true,
                    upload_config: {
                      headers: { UPSTREAM_GID_HEADER => upstream.to_global_id.to_s },
                      authorized_upload_response: authorized_upload_response
                    }
                  )
                )
              end

              def authorized_upload_response
                ::VirtualRegistries::Cache::EntryUploader.workhorse_authorize(
                  has_length: true,
                  maximum_size: MAX_FILE_SIZE,
                  use_final_store_path: true,
                  final_store_path_config: {
                    override_path: upstream.object_storage_key_for(registry_id: registry.id)
                  }
                )
              end

              def send_workhorse_headers(headers)
                header(*headers)
                env['api.format'] = :binary
                content_type 'application/octet-stream'
                status :ok
                body ''
              end

              def ok_empty_response
                status :ok
                env['api.format'] = :binary # to return data as-is
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
