# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module CodeReuse
      # Cop that enforces various code reuse rules for workers.
      class Worker < RuboCop::Cop::Base
        include CodeReuseHelpers

        IN_CONTROLLER = 'Workers can not be used in a controller.'
        IN_API = 'Workers can not be used in an API endpoint.'
        IN_FINDER = 'Workers can not be used in a Finder.'
        IN_PRESENTER = 'Workers can not be used in a Presenter.'
        IN_SERIALIZER = 'Workers can not be used in a Serializer.'

        IN_MODEL_CLASS_METHOD =
          'Workers can not be used in model class methods.'

        SUFFIX = 'Worker'

        def on_class(node)
          if in_model?(node)
            check_model_class_methods(node)
          else
            check_all_send_nodes(node)
          end
        end

        def check_all_send_nodes(node)
          message =
            if in_controller?(node)
              IN_CONTROLLER
            elsif in_api?(node) || in_graphql?(node)
              IN_API
            elsif in_finder?(node)
              IN_FINDER
            elsif in_presenter?(node)
              IN_PRESENTER
            elsif in_serializer?(node)
              IN_SERIALIZER
            end

          disallow_send_to(node, SUFFIX, message) if message
        end

        def check_model_class_methods(node)
          each_class_method(node) do |def_node|
            disallow_send_to(def_node, SUFFIX, IN_MODEL_CLASS_METHOD)
          end
        end
      end
    end
  end
end
