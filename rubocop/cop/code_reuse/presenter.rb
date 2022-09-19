# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module CodeReuse
      # Cop that enforces various code reuse rules for Presenter classes.
      class Presenter < RuboCop::Cop::Base
        include CodeReuseHelpers

        IN_SERVICE = 'Presenters can not be used in a Service class.'
        IN_FINDER = 'Presenters can not be used in a Finder.'
        IN_PRESENTER = 'Presenters can not be used in a Presenter.'
        IN_SERIALIZER = 'Presenters can not be used in a Serializer.'
        IN_MODEL = 'Presenters can not be used in a model.'
        IN_WORKER = 'Presenters can not be used in a worker.'
        SUFFIX = 'Presenter'

        def on_class(node)
          message =
            if in_service_class?(node)
              IN_SERVICE
            elsif in_finder?(node)
              IN_FINDER
            elsif in_presenter?(node)
              IN_PRESENTER
            elsif in_serializer?(node)
              IN_SERIALIZER
            elsif in_model?(node)
              IN_MODEL
            elsif in_worker?(node)
              IN_WORKER
            end

          disallow_send_to(node, SUFFIX, message) if message
        end
      end
    end
  end
end
