# frozen_string_literal: true

module RuboCop
  module Cop
    module Graphql
      class AuthorizeTypes < RuboCop::Cop::Base
        MSG = 'Add an `authorize :ability` call to the type: '\
              'https://docs.gitlab.com/ee/development/graphql_guide/authorization.html#type-authorization'

        # We want to exclude our own basetypes and scalars
        ALLOWED_TYPES = %w[BaseEnum BaseEdge BaseScalar BasePermissionType MutationType SubscriptionType
                           QueryType GraphQL::Schema BaseUnion BaseInputObject].freeze

        # @!method authorize?(node)
        def_node_search :authorize?, <<~PATTERN
          (send nil? :authorize sym+)
        PATTERN

        def on_class(node)
          return if allowed?(class_constant(node))
          return if allowed?(superclass_constant(node))

          add_offense(node) unless authorize?(node)
        end

        private

        def allowed?(class_node)
          class_const = class_node&.const_name

          return false unless class_const
          return true if class_const.end_with?('Enum')
          return true if class_const.end_with?('InputType')

          ALLOWED_TYPES.any? { |allowed| class_const.include?(allowed) }
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
