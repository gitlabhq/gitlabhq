# frozen_string_literal: true

module RuboCop
  module Cop
    module API
      class Base < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector

        # This cop checks that APIs subclass API::Base.
        #
        # @example
        #
        # # bad
        # module API
        #   class Projects < Grape::API
        #   end
        # end
        #
        # module API
        #   class Projects < Grape::API::Instance
        #   end
        # end
        #
        # # good
        # module API
        #   class Projects < ::API::Base
        #   end
        # end
        MSG = 'Inherit from ::API::Base instead of Grape::API::Instance or Grape::API. ' \
              'For more details check https://gitlab.com/gitlab-org/gitlab/-/issues/215230.'

        def_node_matcher :grape_api, '(const (const {nil? (cbase)} :Grape) :API)'
        def_node_matcher :grape_api_definition, <<~PATTERN
          (class
            (const _ _)
            {#grape_api (const #grape_api :Instance)}
            ...
          )
        PATTERN

        def on_class(node)
          grape_api_definition(node) do
            add_offense(node.children[1]) do |corrector|
              corrector.replace(node.children[1], '::API::Base')
            end
          end
        end
      end
    end
  end
end
