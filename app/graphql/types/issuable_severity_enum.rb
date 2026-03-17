# frozen_string_literal: true

module Types
  class IssuableSeverityEnum < BaseEnum
    graphql_name 'IssuableSeverity'
    description 'Incident severity'

    ::IssuableSeverity.severities.each_key do |severity|
      value severity.upcase, value: severity, description: "#{severity.titleize} severity"
    end
  end
end
