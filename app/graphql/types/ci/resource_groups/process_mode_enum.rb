# frozen_string_literal: true

module Types
  module Ci
    module ResourceGroups
      class ProcessModeEnum < BaseEnum
        graphql_name 'ResourceGroupsProcessMode'
        description 'Process mode for resource groups'

        value 'UNORDERED', value: 'unordered', description: 'Unordered.'
        value 'OLDEST_FIRST', value: 'oldest_first', description: 'Oldest first.'
        value 'NEWEST_FIRST', value: 'newest_first', description: 'Newest first.'
        value 'NEWEST_READY_FIRST', value: 'newest_ready_first', description: 'Newest ready first.'
      end
    end
  end
end
