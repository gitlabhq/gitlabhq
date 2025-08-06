# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module CodeReuse
      # Cop that prevents Service class from being used in Finder,
      # Presenter, Serializer, and model to maintain
      # proper separation of concerns and avoid circular dependencies.
      # Services should primarily be used in controllers, API endpoints, and other services.
      #
      # @example
      #   # bad - Service class in a Finder
      #   class SomeFinder
      #     def some_method
      #       SomeService.new(@data)
      #     end
      #   end
      #
      #   # bad - Service class in a Presenter
      #   class SomePresenter
      #     def some_method
      #       SomeService.new(@data)
      #     end
      #   end
      #
      #   # bad - Service class in a Serializer
      #   class SomeSerializer
      #     def some_method
      #       SomeService.new(@data)
      #     end
      #   end
      #
      #   # bad - Service class in a model
      #   class SomeModel < ApplicationRecord
      #     def some_method
      #       SomeService.new(@data)
      #     end
      #   end
      #
      #   # good - Service class in a controller
      #   class SomeController
      #     def some_method
      #       SomeService.new(@data)
      #     end
      #   end
      #
      #   # good - Service class in API endpoint
      #   class Api::SomeController
      #     def some_method
      #       SomeService.new(@data)
      #     end
      #   end
      #
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
