# frozen_string_literal: true

module Types
  module AlertManagement
    class StatusEnum < BaseEnum
      graphql_name 'AlertManagementStatus'
      description 'Alert status values'

      ::AlertManagement::Alert::STATUSES.each do |name, value|
        value name.upcase, value: value, description: "#{name.to_s.titleize} status"
      end
    end
  end
end
