# frozen_string_literal: true

module Types
  class MilestoneWildcardIdEnum < BaseEnum
    graphql_name 'MilestoneWildcardId'
    description 'Milestone ID wildcard values'

    value 'NONE', 'No milestone is assigned.'
    value 'ANY', 'Milestone is assigned.'
    value 'STARTED', 'Milestone assigned is open and started (start date <= today).'
    value 'UPCOMING', 'Milestone assigned is due in the future (due date > today).'
  end
end
