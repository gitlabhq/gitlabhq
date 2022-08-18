# frozen_string_literal: true

module Types
  class IssueTypeEnum < BaseEnum
    graphql_name 'IssueType'
    description 'Issue type'

    ::WorkItems::Type.allowed_types_for_issues.each do |issue_type|
      value issue_type.upcase, value: issue_type, description: "#{issue_type.titleize} issue type"
    end

    value 'TASK', value: 'task',
                  description: 'Task issue type. Available only when feature flag `work_items` is enabled.',
                  alpha: { milestone: '15.2' }
  end
end
