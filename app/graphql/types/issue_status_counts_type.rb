# frozen_string_literal: true

module Types
  class IssueStatusCountsType < BaseObject
    graphql_name 'IssueStatusCountsType'
    description 'Represents total number of issues for the represented statuses'

    authorize :read_issue

    def self.available_issue_states
      @available_issue_states ||= Issue.available_states.keys.push('all')
    end

    ::Gitlab::IssuablesCountForState::STATES.each do |state|
      next unless available_issue_states.include?(state.downcase)

      field state,
        GraphQL::Types::Int,
        null: true,
        description: "Number of issues with status #{state.upcase} for the project"
    end
  end
end
