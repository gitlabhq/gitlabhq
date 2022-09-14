# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module CodeReuse
      # Cop that enforces various code reuse rules for Service classes.
      class ServiceClass < RuboCop::Cop::Base
        include CodeReuseHelpers

        IN_FINDER = 'Service classes can not be used in a Finder.'
        IN_PRESENTER = 'Service classes can not be used in a Presenter.'
        IN_SERIALIZER = 'Service classes can not be used in a Serializer.'
        IN_MODEL = 'Service classes can not be used in a model.'
        SUFFIX = 'Service'

        def on_class(node)
          check_all_send_nodes(node)
        end

        def check_all_send_nodes(node)
          message =
            if in_finder?(node)
              IN_FINDER
            elsif in_presenter?(node)
              IN_PRESENTER
            elsif in_serializer?(node)
              IN_SERIALIZER
            elsif in_model?(node)
              IN_MODEL
            end

          disallow_send_to(node, SUFFIX, message) if message
        end
      end
    end
  end
end
