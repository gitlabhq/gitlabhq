# frozen_string_literal: true

module Types
  class IssueStateEventEnum < BaseEnum
    graphql_name 'IssueStateEvent'
    description 'Values for issue state events'

    value 'REOPEN', 'Reopens the issue.', value: 'reopen'
    value 'CLOSE', 'Closes the issue.', value: 'close'
  end
end
