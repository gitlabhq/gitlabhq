# frozen_string_literal: true

module Types
  class NegatedMilestoneWildcardIdEnum < BaseEnum
    graphql_name 'NegatedMilestoneWildcardId'
    description 'Negated Milestone ID wildcard values'

    value 'STARTED', 'Milestone assigned is open and yet to be started (start date > today).'
    value 'UPCOMING', description: "Milestone assigned is open but starts in the past (start date <= today). " \
                        "This differs from the behavior in the [REST API implementation](https://docs.gitlab.com/api/issues/#list-issues)."
  end
end
