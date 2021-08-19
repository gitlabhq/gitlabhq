# frozen_string_literal: true

module Types
  class NegatedMilestoneWildcardIdEnum < BaseEnum
    graphql_name 'NegatedMilestoneWildcardId'
    description 'Negated Milestone ID wildcard values'

    value 'STARTED', 'An open, started milestone (start date <= today).'
    value 'UPCOMING', 'An open milestone due in the future (due date >= today).'
  end
end
