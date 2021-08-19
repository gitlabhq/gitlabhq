# frozen_string_literal: true

module Types
  class MilestoneWildcardIdEnum < BaseEnum
    graphql_name 'MilestoneWildcardId'
    description 'Milestone ID wildcard values'

    value 'NONE', 'No milestone is assigned.'
    value 'ANY', 'A milestone is assigned.'
    value 'STARTED', 'An open, started milestone (start date <= today).'
    value 'UPCOMING', 'An open milestone due in the future (due date >= today).'
  end
end
