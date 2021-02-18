# frozen_string_literal: true

module Types
  class MergeRequestStateEventEnum < BaseEnum
    graphql_name 'MergeRequestNewState'
    description 'New state to apply to a merge request.'

    value 'OPEN',
      value: 'reopen',
      description: 'Open the merge request if it is closed.'

    value 'CLOSED',
      value: 'close',
      description: 'Close the merge request if it is open.'
  end
end
