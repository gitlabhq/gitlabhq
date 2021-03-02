# frozen_string_literal: true

module Types
  class IssuableStateEnum < BaseEnum
    graphql_name 'IssuableState'
    description 'State of a GitLab issue or merge request'

    value 'opened', description: 'In open state.'
    value 'closed', description: 'In closed state.'
    value 'locked', description: 'Discussion has been locked.'
    value 'all', description: 'All available.'
  end
end
