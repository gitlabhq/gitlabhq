# frozen_string_literal: true

module VirtualRegistries
  module Packages
    module Maven
      class HandleFileRequestService < ::BaseContainerService
        alias_method :registry, :container

        TIMEOUT = 5

        def initialize(registry:, current_user: nil, params: {})
          super(container: registry, current_user: current_user, params: params)
        end

        def execute
          return ServiceResponse.error(message: 'Path not present', reason: :path_not_present) unless path.present?
          return ServiceResponse.error(message: 'Unauthorized', reason: :unauthorized) unless allowed?

          unless registry.upstream.present?
            return ServiceResponse.error(message: 'No upstreams set', reason: :no_upstreams)
          end

          # TODO check cached responses here
          # If one exists and can be used, return it.
          # https://gitlab.com/gitlab-org/gitlab/-/issues/467983
          handle_upstream(registry.upstream)
        end

        private

        def handle_upstream(upstream)
          url = upstream.url_for(path)
          headers = upstream.headers
          response = head_upstream(url: url, headers: headers)

          if response.success?
            workhorse_send_url_response(url: url, headers: headers)
          else
            ServiceResponse.error(message: 'File not found on any upstream', reason: :file_not_found_on_upstreams)
          end
        rescue *::Gitlab::HTTP::HTTP_ERRORS
          ServiceResponse.error(message: 'Upstream not available', reason: :upstream_not_available)
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

        def workhorse_send_url_response(url:, headers:)
          ServiceResponse.success(
            payload: { action: :workhorse_send_url, action_params: { url: url, headers: headers } }
          )
        end
      end
    end
  end
end
