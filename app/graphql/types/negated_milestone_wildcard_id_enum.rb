# frozen_string_literal: true

module Types
  class NegatedMilestoneWildcardIdEnum < BaseEnum
    graphql_name 'NegatedMilestoneWildcardId'
    description 'Negated Milestone ID wildcard values'

    value 'STARTED', 'Milestone assigned is open and yet to be started (start date > today).'
    value 'UPCOMING', 'Milestone assigned is open but due in the past (due date <= today).'
  end
end
