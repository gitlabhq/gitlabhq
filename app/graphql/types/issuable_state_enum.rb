# frozen_string_literal: true

module Types
  class IssuableStateEnum < BaseEnum
    graphql_name 'IssuableState'
    description 'State of a GitLab issue or merge request'

    value 'opened'
    value 'closed'
    value 'locked'
    value 'all'
  end
end
