# frozen_string_literal: true

module Types
  module Admin
    module SidekiqQueues
      # We can't authorize against the value passed to this because it's
      # a plain hash.
      class DeleteJobsResponseType < BaseObject # rubocop:disable Graphql/AuthorizeTypes
        graphql_name 'DeleteJobsResponse'
        description 'The response from the AdminSidekiqQueuesDeleteJobs mutation'

        field :completed,
              GraphQL::Types::Boolean,
              null: true,
              description: 'Whether or not the entire queue was processed in time; if not, retrying the same request is safe.'

        field :deleted_jobs,
              GraphQL::Types::Int,
              null: true,
              description: 'The number of matching jobs deleted.'

        field :queue_size,
              GraphQL::Types::Int,
              null: true,
              description: 'The queue size after processing.'
      end
    end
  end
end
