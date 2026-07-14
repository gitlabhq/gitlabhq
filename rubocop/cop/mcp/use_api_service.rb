# frozen_string_literal: true

module RuboCop
  module Cop
    module Mcp
      # Checks that MCP tool services inherit from ApiService
      # instead of directly from BaseService.
      #
      # The framework base classes live under Mcp::Tools::Base, so direct
      # inheritance is written as `Base::BaseService` (or the fully-qualified
      # `::Mcp::Tools::Base::BaseService`). Both forms are flagged.
      #
      # @example
      #
      #   # bad
      #   module Mcp
      #     module Tools
      #       class CustomTool < Base::BaseService
      #       end
      #     end
      #   end
      #
      #   module Mcp
      #     module Tools
      #       class CustomTool < ::Mcp::Tools::Base::BaseService
      #       end
      #     end
      #   end
      #
      #   # good
      #   module Mcp
      #     module Tools
      #       class CustomTool < Base::ApiService
      #       end
      #     end
      #   end
      #
      #   module Mcp
      #     module Tools
      #       class CustomTool < ::Mcp::Tools::Base::ApiService
      #       end
      #     end
      #   end
      class UseApiService < RuboCop::Cop::Base
        MSG = 'Inherit from ApiService when API endpoints exist for this functionality. ' \
          'ApiService handles authentication/authorization automatically via API requests. ' \
          'Direct BaseService inheritance requires implementing manual Ability checks.'

        ALLOWED_SUBCLASS = 'ApiService'

        # Matches BaseService referenced by any constant path: bare `BaseService`,
        # `Base::BaseService`, or `::Mcp::Tools::Base::BaseService`. The cop is
        # scoped to app/services/mcp/tools/**/* via Include, so matching the leaf
        # name is unambiguous.
        # @!method base_service(node)
        def_node_matcher :base_service, '(const _ :BaseService)'

        # @!method base_service_definition(node)
        def_node_matcher :base_service_definition, <<~PATTERN
          (class
            (const _ $...)
            #base_service
            ...
          )
        PATTERN

        def on_class(node)
          base_service_definition(node) do |class_name_parts|
            class_name = class_name_parts.last
            next if class_name.to_s == ALLOWED_SUBCLASS

            add_offense(node.children[1])
          end
        end
      end
    end
  end
end
