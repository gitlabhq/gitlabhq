# frozen_string_literal: true

module Types
  class MilestoneStatsType < BaseObject
    graphql_name 'MilestoneStats'
    description 'Contains statistics about a milestone'

    authorize :read_milestone

    field :total_issues_count,
      GraphQL::Types::Int,
      null: true,
      description: 'Total number of issues associated with the milestone.'

    field :closed_issues_count,
      GraphQL::Types::Int,
      null: true,
      description: 'Number of closed issues associated with the milestone.'
  end
end
