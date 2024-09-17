# frozen_string_literal: true

module VirtualRegistries
  module Packages
    module Maven
      class HandleFileRequestService < ::BaseContainerService
        alias_method :registry, :container

        TIMEOUT = 5

        ERRORS = {
          path_not_present: ServiceResponse.error(message: 'Path not present', reason: :path_not_present),
          unauthorized: ServiceResponse.error(message: 'Unauthorized', reason: :unauthorized),
          no_upstreams: ServiceResponse.error(message: 'No upstreams set', reason: :no_upstreams),
          file_not_found_on_upstreams: ServiceResponse.error(
            message: 'File not found on any upstream',
            reason: :file_not_found_on_upstreams
          ),
          upstream_not_available: ServiceResponse.error(
            message: 'Upstream not available',
            reason: :upstream_not_available
          )
        }.freeze

        def initialize(registry:, current_user: nil, params: {})
          super(container: registry, current_user: current_user, params: params)
        end

        def execute
          return ERRORS[:path_not_present] unless path.present?
          return ERRORS[:unauthorized] unless allowed?
          return ERRORS[:no_upstreams] unless registry.upstream.present?

          if cache_response_still_valid?
            download_cached_response
          else
            check_upstream(registry.upstream)
          end

        rescue *::Gitlab::HTTP::HTTP_ERRORS
          ERRORS[:upstream_not_available]
        end

        private

        def cached_response
          # TODO change this to support multiple upstreams
          # https://gitlab.com/gitlab-org/gitlab/-/issues/480461
          registry.upstream.cached_responses.find_by_relative_path(relative_path)
        end
        strong_memoize_attr :cached_response

        def cache_response_still_valid?
          return false unless cached_response.present?

          unless cached_response.stale?(registry: registry)
            cached_response.bump_statistics
            return true
          end
          # cached response with no etag can't be checked
          return false if cached_response.upstream_etag.blank?

          upstream = cached_response.upstream
          response = head_upstream(url: upstream.url_for(path), headers: upstream.headers)

          return false unless cached_response.upstream_etag == response.headers['etag']

          cached_response.bump_statistics(include_upstream_checked_at: true)
          true
        end

        def check_upstream(upstream)
          url = upstream.url_for(path)
          headers = upstream.headers
          response = head_upstream(url: url, headers: headers)

          return ERRORS[:file_not_found_on_upstreams] unless response.success?

          workhorse_upload_url_response(url: url, upstream: upstream)
        end

        def head_upstream(url:, headers:)
          ::Gitlab::HTTP.head(url, headers: headers, follow_redirects: true, timeout: TIMEOUT)
        end

        def allowed?
          can?(current_user, :read_virtual_registry, registry)
        end

        def path
          params[:path]
        end

        def relative_path
          "/#{path}"
        end

        def download_cached_response
          ServiceResponse.success(
            payload: {
              action: :download_file,
              action_params: { file: cached_response.file, content_type: cached_response.content_type }
            }
          )
        end

        def workhorse_upload_url_response(url:, upstream:)
          ServiceResponse.success(
            payload: {
              action: :workhorse_upload_url,
              action_params: { url: url, upstream: upstream }
            }
          )
        end
      end
    end
  end
end
