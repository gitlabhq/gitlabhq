# frozen_string_literal: true

module Types
  class IssueTypeEnum < BaseEnum
    graphql_name 'IssueType'
    description 'Issue type'

    ::WorkItems::Type.allowed_types_for_issues.each do |issue_type|
      value issue_type.upcase, value: issue_type, description: "#{issue_type.titleize} issue type"
    end

    value 'OBJECTIVE', value: 'objective',
      description: 'Objective issue type. Available only when feature flag `okrs_mvc` is enabled.',
      experiment: { milestone: '15.6' }

    value 'KEY_RESULT', value: 'key_result',
      description: 'Key Result issue type. Available only when feature flag `okrs_mvc` is enabled.',
      experiment: { milestone: '15.7' }
    value 'EPIC', value: 'epic',
      description: 'Epic issue type. ' \
        'Available only when feature epics is available and the feature flag `work_item_epics` is enabled.',
      experiment: { milestone: '16.7' }
  end
end
