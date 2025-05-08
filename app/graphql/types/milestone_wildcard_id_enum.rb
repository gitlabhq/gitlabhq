# frozen_string_literal: true

module Types
  class MilestoneWildcardIdEnum < BaseEnum
    graphql_name 'MilestoneWildcardId'
    description 'Milestone ID wildcard values'

    value 'NONE', 'No milestone is assigned.'
    value 'ANY', 'Milestone is assigned.'
    value 'STARTED', description: "Milestone assigned is open and started (overlaps current date). This " \
                       "differs from the behavior in the [REST API implementation](https://docs.gitlab.com/api/issues/#list-issues)."
    value 'UPCOMING', description: "Milestone assigned starts in the future (start date > today). This differs " \
                        "from the behavior in the [REST API implementation](https://docs.gitlab.com/api/issues/#list-issues)."
  end
end
