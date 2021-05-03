# frozen_string_literal: true

module Types
  module AlertManagement
    class StatusEnum < BaseEnum
      graphql_name 'AlertManagementStatus'
      description 'Alert status values'

      ::AlertManagement::Alert.status_names.each do |status|
        value status.to_s.upcase, value: status, description: "#{::AlertManagement::Alert::STATUS_DESCRIPTIONS[status]}."
      end
    end
  end
end
