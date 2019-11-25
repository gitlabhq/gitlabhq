# frozen_string_literal: true

module RuboCop
  module Cop
    module Graphql
      class AuthorizeTypes < RuboCop::Cop::Cop
        MSG = 'Add an `authorize :ability` call to the type: '\
              'https://docs.gitlab.com/ee/development/api_graphql_styleguide.html#type-authorization'

        TYPES_DIR = 'app/graphql/types'

        # We want to exclude our own basetypes and scalars
        WHITELISTED_TYPES = %w[BaseEnum BaseScalar BasePermissionType MutationType
                               QueryType GraphQL::Schema BaseUnion].freeze

        def_node_search :authorize?, <<~PATTERN
          (send nil? :authorize ...)
        PATTERN

        def on_class(node)
          return unless in_type?(node)
          return if whitelisted?(class_constant(node))
          return if whitelisted?(superclass_constant(node))

          add_offense(node, location: :expression) unless authorize?(node)
        end

        private

        def in_type?(node)
          path = node.location.expression.source_buffer.name

          path.include? TYPES_DIR
        end

        def whitelisted?(class_node)
          class_const = class_node&.const_name

          return false unless class_const
          return true if class_const.end_with?('Enum')

          WHITELISTED_TYPES.any? { |whitelisted| class_node.const_name.include?(whitelisted) }
        end

        def class_constant(node)
          node.descendants.first
        end

        def superclass_constant(class_node)
          # First one is the class name itself, second is its superclass
          _class_constant, *others = class_node.descendants

          others.find { |node| node.const_type? && node&.const_name != 'Types' }
        end
      end
    end
  end
end
