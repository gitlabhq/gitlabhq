# frozen_string_literal: true

module Types
  module WebHooks
    class BranchFilterStrategyEnum < BaseEnum
      graphql_name 'WebhookBranchFilterStrategy'
      description 'Strategy for filtering push events by branch name'

      value 'WILDCARD',
        description: 'Receive push events from branches that match a wildcard pattern.',
        value: 'wildcard'

      value 'REGEX',
        description: 'Receive push events from branches that match a regular expression (regex).',
        value: 'regex'

      value 'ALL_BRANCHES',
        description: 'Receive push events from all branches.',
        value: 'all_branches'
    end
  end
end
