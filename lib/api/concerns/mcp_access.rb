# frozen_string_literal: true

module API
  module Concerns
    module McpAccess
      extend ActiveSupport::Concern

      class_methods do
        def allow_mcp_access_read
          allow_access_with_scope :mcp, if: ->(request) { request.get? || request.head? }
        end

        def allow_mcp_access_create
          allow_access_with_scope :mcp, if: ->(request) { request.post? }
        end
      end
    end
  end
end
