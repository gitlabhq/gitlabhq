# frozen_string_literal: true

module Types
  module AlertManagement
    class StatusEnum < BaseEnum
      graphql_name 'AlertManagementStatus'
      description 'Alert status values'

      ::AlertManagement::Alert.statuses.keys.each do |status|
        value status.upcase, value: status, description: "#{status.titleize} status"
      end
    end
  end
end
