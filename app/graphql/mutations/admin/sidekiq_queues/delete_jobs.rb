# frozen_string_literal: true

module Mutations
  module Admin
    module SidekiqQueues
      class DeleteJobs < BaseMutation
        graphql_name 'AdminSidekiqQueuesDeleteJobs'

        ADMIN_MESSAGE = 'You must be an admin to use this mutation'

        ::Gitlab::ApplicationContext.allowed_job_keys.each do |key|
          argument key,
            GraphQL::Types::String,
            required: false,
            description: "Delete jobs matching #{key} in the context metadata."
        end

        argument ::Gitlab::SidekiqQueue::WORKER_KEY,
          GraphQL::Types::String,
          required: false,
          description: 'Delete jobs with the given worker class.'

        argument :queue_name,
          GraphQL::Types::String,
          required: true,
          description: 'Name of the queue to delete jobs from.'

        field :result,
          Types::Admin::SidekiqQueues::DeleteJobsResponseType,
          null: true,
          description: 'Information about the status of the deletion request.'

        def ready?(**args)
          raise Gitlab::Graphql::Errors::ResourceNotAvailable, ADMIN_MESSAGE unless current_user&.admin?

          super
        end

        def resolve(queue_name:, **args)
          {
            result: Gitlab::SidekiqQueue.new(queue_name).drop_jobs!(args, timeout: 30),
            errors: []
          }
        rescue Gitlab::SidekiqQueue::NoMetadataError
          {
            result: nil,
            errors: ['No metadata provided']
          }
        rescue Gitlab::SidekiqQueue::InvalidQueueError
          raise Gitlab::Graphql::Errors::ResourceNotAvailable, "Queue #{queue_name} not found"
        end
      end
    end
  end
end
