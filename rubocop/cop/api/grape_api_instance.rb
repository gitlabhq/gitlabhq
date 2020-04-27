# frozen_string_literal: true

module RuboCop
  module Cop
    module API
      class GrapeAPIInstance < RuboCop::Cop::Cop
        # This cop checks that APIs subclass Grape::API::Instance with Grape v1.3+.
        #
        # @example
        #
        # # bad
        # module API
        #   class Projects < Grape::API
        #   end
        # end
        #
        # # good
        # module API
        #   class Projects < Grape::API::Instance
        #   end
        # end
        MSG = 'Inherit from Grape::API::Instance instead of Grape::API. ' \
              'For more details check the https://gitlab.com/gitlab-org/gitlab/-/issues/215230.'

        def_node_matcher :grape_api_definition, <<~PATTERN
          (class
            (const _ _)
            (const
              (const nil? :Grape) :API)
            ...
          )
        PATTERN

        def on_class(node)
          grape_api_definition(node) do
            add_offense(node.children[1])
          end
        end
      end
    end
  end
end
