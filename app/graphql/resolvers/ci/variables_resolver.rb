# frozen_string_literal: true

module Resolvers
  module Ci
    class VariablesResolver < BaseResolver
      type Types::Ci::InstanceVariableType.connection_type, null: true

      argument :sort, ::Types::Ci::VariableSortEnum,
        required: false,
        description: 'Sort order of results.'

      def resolve(**args)
        if parent.is_a?(Group) || parent.is_a?(Project)
          parent.variables.order_by(args[:sort])
        elsif current_user&.can_admin_all_resources?
          ::Ci::InstanceVariable.order_by(args[:sort])
        end
      end

      private

      def parent
        object.respond_to?(:sync) ? object.sync : object
      end
    end
  end
end
