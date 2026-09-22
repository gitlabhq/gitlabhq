# frozen_string_literal: true

module Types
  module MergeRequests
    class ResourceLabelEventActionEnum < BaseEnum
      graphql_name 'ResourceLabelEventAction'
      description 'Action taken on a resource label event.'

      ::ResourceLabelEvent.actions.each_key do |action|
        value action.upcase, value: action, description: "#{action.titleize} action."
      end
    end
  end
end
