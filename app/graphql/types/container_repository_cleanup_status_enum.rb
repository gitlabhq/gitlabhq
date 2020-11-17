# frozen_string_literal: true

module Types
  class ContainerRepositoryCleanupStatusEnum < BaseEnum
    graphql_name 'ContainerRepositoryCleanupStatus'
    description 'Status of the tags cleanup of a container repository'

    value 'UNSCHEDULED', value: 'cleanup_unscheduled', description: 'The tags cleanup is not scheduled. This is the default state.'
    value 'SCHEDULED', value: 'cleanup_scheduled', description: 'The tags cleanup is scheduled and is going to be executed shortly.'
    value 'UNFINISHED', value: 'cleanup_unfinished', description: 'The tags cleanup has been partially executed. There are still remaining tags to delete.'
    value 'ONGOING', value: 'cleanup_ongoing', description: 'The tags cleanup is ongoing.'
  end
end
