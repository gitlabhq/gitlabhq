# frozen_string_literal: true

module RuboCop
  module Cop
    module Mcp
      # Checks that MCP tool services inherit from ApiService
      # instead of directly from BaseService.
      #
      # @example
      #
      #   # bad
      #   module Mcp
      #     module Tools
      #       class CustomTool < BaseService
      #       end
      #     end
      #   end
      #
      #   module Mcp
      #     module Tools
      #       class CustomTool < ::Mcp::Tools::BaseService
      #       end
      #     end
      #   end
      #
      #   # good
      #   module Mcp
      #     module Tools
      #       class CustomTool < ApiService
      #       end
      #     end
      #   end
      #
      #   module Mcp
      #     module Tools
      #       class CustomTool < ::Mcp::Tools::ApiService
      #       end
      #     end
      #   end
      class UseApiService < RuboCop::Cop::Base
        MSG = 'Inherit from ApiService when API endpoints exist for this functionality. ' \
          'ApiService handles authentication/authorization automatically via API requests. ' \
          'Direct BaseService inheritance requires implementing manual Ability checks.'

        ALLOWED_SUBCLASS = 'ApiService'

        # @!method base_service(node)
        def_node_matcher :base_service, '(const (const (const {nil? (cbase)} :Mcp) :Tools) :BaseService)'

        # @!method base_service_definition(node)
        def_node_matcher :base_service_definition, <<~PATTERN
          (class
            (const _ $...)
            {#base_service (const {nil? (cbase)} :BaseService)}
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
