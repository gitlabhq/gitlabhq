# frozen_string_literal: true

module Types
  class MilestoneStateEnum < BaseEnum
    graphql_name 'MilestoneStateEnum'
    description 'Current state of milestone'

    value 'active', 'Milestone is currently active'
    value 'closed', 'Milestone is closed'
  end
end
