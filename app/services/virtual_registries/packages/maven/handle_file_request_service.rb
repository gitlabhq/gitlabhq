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

          # TODO check cached responses here
          # If one exists and can be used, return it.
          # https://gitlab.com/gitlab-org/gitlab/-/issues/467983
          check_upstream(registry.upstream)
        end

        private

        def check_upstream(upstream)
          url = upstream.url_for(path)
          headers = upstream.headers
          response = head_upstream(url: url, headers: headers)

          return ERRORS[:file_not_found_on_upstreams] unless response.success?

          workhorse_upload_url_response(url: url, upstream: upstream)
        rescue *::Gitlab::HTTP::HTTP_ERRORS
          ERRORS[:upstream_not_available]
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
