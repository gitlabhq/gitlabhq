# frozen_string_literal: true

module RuboCop
  module Cop
    module Search
      # Cop that enforces use of Search namespace for search related code.
      #
      # @example
      #   # bad
      #   class MySearchClass
      #   end
      #
      #   # good
      #   module Search
      #     class MySearchClass
      #     end
      #   end
      class NamespacedClass < RuboCop::Cop::Base
        MSG = 'Search related code must be declared inside Search top level namespace. For more info: https://gitlab.com/gitlab-org/gitlab/-/issues/398207'

        # These namespaces are considered acceptable.
        # Note: Nested namespace like Foo::Bar are also supported.
        PERMITTED_NAMESPACES = %w[
          Search EE::Search API::Search EE::API::Search API::Admin::Search RuboCop::Cop::Search Types Resolvers
          API::Entities::Search::Zoekt API::Internal::Search::Zoekt
          Keeps
          Gitlab::SidekiqMiddleware::PauseControl::Strategies::AdvancedSearch
        ].map { |x| x.split('::') }.freeze

        SEARCH_REGEXES = [
          /elastic/i,
          /zoekt/i,
          /search/i
        ].freeze

        def on_module(node)
          add_identifiers(node)

          run_search_namespace_cop(node) if node.child_nodes.none? { |n| n.module_type? || n.class_type? }
        end

        def on_class(node)
          add_identifiers(node)
          run_search_namespace_cop(node)
        end

        private

        def run_search_namespace_cop(node)
          add_offense(node.loc.name) if !namespace_allowed? && namespace_search_related?
        end

        def add_identifiers(node)
          identifiers.concat(identifiers_for(node))
        end

        def identifiers
          @identifiers ||= []
        end

        def identifiers_for(node)
          source = node.respond_to?(:identifier) ? node.identifier.source : node.source
          source.sub(/^::/, '').split('::')
        end

        def namespace_allowed?
          PERMITTED_NAMESPACES.any? do |namespaces|
            identifiers.first(namespaces.size) == namespaces
          end
        end

        def namespace_search_related?
          SEARCH_REGEXES.any? { |x| x.match?(identifiers.join('::')) }
        end
      end
    end
  end
end
