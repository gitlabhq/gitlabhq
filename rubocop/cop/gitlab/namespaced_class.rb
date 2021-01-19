# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Cop that enforces use of namespaced classes in order to better identify
      # high level domains within the codebase.

      # @example
      #   # bad
      #   class MyClass
      #   end
      #
      #   # good
      #   module MyDomain
      #     class MyClass
      #     end
      #   end

      class NamespacedClass < RuboCop::Cop::Cop
        MSG = 'Classes must be declared inside a module indicating a product domain namespace. For more info: https://gitlab.com/gitlab-org/gitlab/-/issues/212156'

        def_node_matcher :compact_namespaced_class?, <<~PATTERN
          (class (const (const ...) ...) ...)
        PATTERN

        def on_module(node)
          @namespaced = true
        end

        def on_class(node)
          return if @namespaced

          add_offense(node) unless compact_namespaced_class?(node)
        end
      end
    end
  end
end
