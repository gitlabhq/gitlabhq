# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module CodeReuse
      # Cop that prevents Presenters from being used in Service class,
      # Finder, Presenter, Serializer, model and worker
      # to maintain clean and proper separation of concerns  and avoid circular dependencies.
      #
      # @example
      #
      #   # bad - Presenter used in a Service class
      #   class SomeService
      #     def some_method
      #       SomePresenter.new(@data).name
      #     end
      #   end
      #
      #   # bad - Presenter used in a Finder
      #   class SomeFinder
      #     def some_method
      #       SomePresenter.new(@data)
      #     end
      #   end
      #
      #   # bad - Presenter used in another Presenter
      #   class SomePresenter
      #     def some_method
      #       FooPresenter.new(@data)
      #     end
      #   end
      #
      #   # bad - Presenter used in a model
      #   class SomeModel < ApplicationRecord
      #     def some_method
      #       SomePresenter.new(@data)
      #     end
      #   end
      #
      #   # bad - Presenter used in a Serializer
      #   class SomeSerializer
      #     def some_method
      #       SomePresenter.new(@data)
      #     end
      #   end
      #
      #   # bad - Presenter used in a worker
      #   class SomeWorker
      #     def some_method
      #       SomePresenter.new(@data)
      #     end
      #   end
      #
      #   # good - Presenter used in a controller
      #   class SomeController
      #     def some_method
      #       SomePresenter.new(@data)
      #     end
      #   end
      #
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
