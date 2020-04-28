# frozen_string_literal: true

module Resolvers
  class AlertManagementAlertResolver < BaseResolver
    argument :iid, GraphQL::STRING_TYPE,
              required: false,
              description: 'IID of the alert. For example, "1"'

    type Types::AlertManagement::AlertType, null: true

    def resolve(**args)
      parent = object.respond_to?(:sync) ? object.sync : object
      return AlertManagement::Alert.none if parent.nil?

      AlertManagement::AlertsFinder.new(context[:current_user], parent, args).execute
    end
  end
end
