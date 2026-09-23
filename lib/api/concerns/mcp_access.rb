# frozen_string_literal: true

module API
  module Concerns
    module McpAccess
      extend ActiveSupport::Concern

      class_methods do
        def allow_mcp_access_read
          allow_mcp_access_for_verb(->(request) { request.get? || request.head? })
        end

        def allow_mcp_access_create
          allow_mcp_access_for_verb(->(request) { request.post? })
        end

        def allow_mcp_access_update
          allow_mcp_access_for_verb(->(request) { request.put? || request.patch? })
        end

        def allow_mcp_access_delete
          allow_mcp_access_for_verb(->(request) { request.delete? })
        end

        private

        # An `mcp`-scoped token may only authenticate for the specific route it was
        # granted for, not every route sharing the same HTTP verb in this resource.
        # `present?` matches how `Mcp::Tools::Manager` decides a route is a tool, so a
        # route can never be authorized here and skipped there.
        def allow_mcp_access_for_verb(verb_condition)
          allow_access_with_scope :mcp, if: ->(request) {
            verb_condition.call(request) && request.env[Grape::Env::API_ENDPOINT]&.route_setting(:mcp).present?
          }
        end
      end
    end
  end
end
