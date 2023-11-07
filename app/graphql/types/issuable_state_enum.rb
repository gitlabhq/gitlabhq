# frozen_string_literal: true

# DO NOT use this ENUM with issues. We need to define a new enum in places where we
# need to filter by state. locked is not a valid state filter for issues. More info in
# https://gitlab.com/gitlab-org/gitlab/-/issues/420667#note_1605900474
module Types
  class IssuableStateEnum < BaseEnum
    graphql_name 'IssuableState'
    description 'State of a GitLab issue or merge request'

    INVALID_LOCKED_MESSAGE = 'locked is not a valid state filter for issues.'

    value 'opened', description: 'In open state.'
    value 'closed', description: 'In closed state.'
    value 'locked', description: 'Discussion has been locked.'
    value 'all', description: 'All available.'
  end
end
