# frozen_string_literal: true

module Types
  module AlertManagement
    class SeverityEnum < BaseEnum
      graphql_name 'AlertManagementSeverity'
      description 'Alert severity values'

      ::AlertManagement::Alert.severities.keys.each do |severity|
        value severity.upcase, value: severity, description: "#{severity.titleize} severity"
      end
    end
  end
end
