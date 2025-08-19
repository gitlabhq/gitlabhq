# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module CodeReuse
      # Cop that prevents Serializers from being used in Service class,
      # Finder, Presenter, Serializer, model, and worker to maintain
      # proper separation of concerns and avoid circular dependencies.
      #
      # @example
      #   # bad - Serializer used in a Service class
      #   class SomeService
      #     def some_method
      #       SomeSerializer.new(@data)
      #     end
      #   end
      #
      #   # bad - Serializer used in a Finder
      #   class SomeFinder
      #     def some_method
      #       SomeSerializer.new(@data)
      #     end
      #   end
      #
      #   # bad - Serializer used in a Presenter
      #   class SomePresenter
      #     def some_method
      #       SomeSerializer.new(@data)
      #     end
      #   end
      #
      #   # bad - Serializer used in another Serializer
      #   class FooSerializer
      #     def some_method
      #       SomeSerializer.new(@data)
      #     end
      #   end
      #
      #   # bad - Serializer used in a model
      #   class SomeModel < ApplicationRecord
      #     def some_method
      #       SomeSerializer.new(@data)
      #     end
      #   end
      #
      #   # bad - Serializer used in a worker
      #   class SomeWorker
      #     def perform
      #       SomeSerializer.new(@data)
      #     end
      #   end
      #
      #   # good - Serializer used in a controller
      #   class SomeController
      #     def some_method
      #       SomeSerializer.new(@data)
      #     end
      #   end
      #
      #   # good - Serializer used in API endpoint
      #   class Api::SomeController
      #     def some_method
      #       SomeSerializer.new(@data)
      #     end
      #   end
      #
      class Serializer < RuboCop::Cop::Base
        include CodeReuseHelpers

        IN_SERVICE = 'Serializers can not be used in a Service class.'
        IN_FINDER = 'Serializers can not be used in a Finder.'
        IN_PRESENTER = 'Serializers can not be used in a Presenter.'
        IN_SERIALIZER = 'Serializers can not be used in a Serializer.'
        IN_MODEL = 'Serializers can not be used in a model.'
        IN_WORKER = 'Serializers can not be used in a worker.'
        SUFFIX = 'Serializer'

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
