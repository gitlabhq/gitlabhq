# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Cop that enforces use of namespaced classes in order to better identify
      # high level domains within the codebase.
      #
      # @example
      #   # bad
      #   class MyClass
      #   end
      #
      #   module Gitlab
      #     class MyClass
      #     end
      #   end
      #
      #   class Gitlab::MyClass
      #   end
      #
      #   # good
      #   module MyDomain
      #     class MyClass
      #     end
      #   end
      #
      #   module Gitlab
      #     module MyDomain
      #       class MyClass
      #       end
      #     end
      #   end
      #
      #   class Gitlab::MyDomain::MyClass
      #   end
      class NamespacedClass < RuboCop::Cop::Base
        MSG = 'Classes must be declared inside a module indicating a product domain namespace. ' \
          'For more info: https://docs.gitlab.com/ee/development/software_design.html#bounded-contexts'

        # These namespaces are considered top-level semantically.
        # Note: Nested namespace like Foo::Bar are also supported.
        PSEUDO_TOPLEVEL = %w[Gitlab]
          .map { _1.split('::') }.freeze

        def on_module(node)
          add_potential_domain_namespace(node)
        end

        def on_class(node)
          # Add potential namespaces from compact definitions like `class Foo::Bar`.
          # Remove class name because it's not a domain namespace.
          add_potential_domain_namespace(node) { _1.pop }

          add_offense(node.loc.name) if domain_namespaces.none?
        end

        private

        def domain_namespaces
          @domain_namespaces ||= []
        end

        def add_potential_domain_namespace(node)
          return if domain_namespaces.any?

          identifiers = identifiers_for(node)
          yield(identifiers) if block_given?

          PSEUDO_TOPLEVEL.each do |namespaces|
            identifiers.shift(namespaces.size) if namespaces == identifiers.first(namespaces.size)
          end

          domain_namespaces.concat(identifiers)
        end

        def identifiers_for(node)
          node.identifier.source.sub(/^::/, '').split('::')
        end
      end
    end
  end
end
