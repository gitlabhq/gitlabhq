# frozen_string_literal: true

module Types
  class IssueTypeEnum < BaseEnum
    graphql_name 'IssueType'
    description 'Issue type'

    ::Issue.issue_types.keys.each do |issue_type|
      value issue_type.upcase, value: issue_type, description: "#{issue_type.titleize} issue type"
    end
  end
end
