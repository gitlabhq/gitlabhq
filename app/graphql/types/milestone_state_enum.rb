# frozen_string_literal: true

module Types
  class MilestoneStateEnum < BaseEnum
    graphql_name 'MilestoneStateEnum'
    description 'Current state of milestone'

    value 'active', description: 'Milestone is currently active.'
    value 'closed', description: 'Milestone is closed.'
  end
end
