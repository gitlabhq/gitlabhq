# frozen_string_literal: true

module Types
  module ContainerRegistry
    class ContainerRepositoryCleanupStatusEnum < BaseEnum
      graphql_name 'ContainerRepositoryCleanupStatus'
      description 'Status of the tags cleanup of a container repository'

      value 'UNSCHEDULED', value: 'cleanup_unscheduled',
        description: 'Tags cleanup is not scheduled. This is the default state.'
      value 'SCHEDULED', value: 'cleanup_scheduled',
        description: 'Tags cleanup is scheduled and is going to be executed shortly.'
      value 'UNFINISHED', value: 'cleanup_unfinished',
        description: 'Tags cleanup has been partially executed. There are still remaining tags to delete.'
      value 'ONGOING', value: 'cleanup_ongoing', description: 'Tags cleanup is ongoing.'
    end
  end
end
