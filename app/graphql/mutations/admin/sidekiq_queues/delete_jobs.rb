# frozen_string_literal: true

module Mutations
  module Admin
    module SidekiqQueues
      class DeleteJobs < BaseMutation
        graphql_name 'AdminSidekiqQueuesDeleteJobs'

        ADMIN_MESSAGE = 'You must be an admin to use this mutation'

        Gitlab::ApplicationContext::KNOWN_KEYS.each do |key|
          argument key,
                   GraphQL::STRING_TYPE,
                   required: false,
                   description: "Delete jobs matching #{key} in the context metadata"
        end

        argument :queue_name,
                 GraphQL::STRING_TYPE,
                 required: true,
                 description: 'The name of the queue to delete jobs from.'

        field :result,
              Types::Admin::SidekiqQueues::DeleteJobsResponseType,
              null: true,
              description: 'Information about the status of the deletion request.'

        def ready?(**args)
          unless current_user&.admin?
            raise Gitlab::Graphql::Errors::ResourceNotAvailable, ADMIN_MESSAGE
          end

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
