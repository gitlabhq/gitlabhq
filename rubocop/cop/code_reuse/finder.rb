# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module CodeReuse
      # Cop that prevents Finders from being used in other Finders
      # and in model class methods to maintain proper separation of concerns
      # and avoid circular dependencies.
      #
      # @example
      #   # bad - Finder used in another Finder
      #   class SomeFinder
      #     def some_method
      #       FooFinder.new.execute
      #     end
      #   end
      #
      #   # bad - Finder used in Model class method
      #   class SomeModel < ApplicationRecord
      #     def self.some_method
      #       SomeFinder.new.execute
      #     end
      #   end
      #
      #   # good - Finder used outside of another Finder or Model
      #   class SomeController
      #     def some_method
      #       SomeFinder.new.execute
      #     end
      #   end
      #
      class Finder < RuboCop::Cop::Base
        include CodeReuseHelpers

        IN_FINDER = 'Finders can not be used inside a Finder.'

        IN_MODEL_CLASS_METHOD =
          'Finders can not be used inside model class methods.'

        SUFFIX = 'Finder'

        def on_class(node)
          if in_finder?(node)
            check_finder(node)
          elsif in_model?(node)
            check_model_class_methods(node)
          end
        end

        def check_finder(node)
          disallow_send_to(node, SUFFIX, IN_FINDER)
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
