# frozen_string_literal: true

module Mutations
  module Ci
    class SafeDisablePipelineVariables < BaseMutation
      graphql_name 'SafeDisablePipelineVariables'

      include Mutations::ResolvesGroup

      authorize :admin_group

      argument :full_path, GraphQL::Types::ID,
        required: true,
        description: 'Full path of the group to disable pipeline variables for.'

      field :success,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Indicates whether the migration was successfully enqueued.'

      def resolve(full_path:)
        group = authorized_find!(full_path)

        # rubocop:disable CodeReuse/Worker -- GraphQL mutation needs to enqueue worker
        ::Ci::SafeDisablePipelineVariablesWorker.perform_async(current_user.id, group.id)
        # rubocop:enable CodeReuse/Worker

        {
          success: true,
          errors: []
        }
      end

      private

      def find_object(full_path)
        resolve_group(full_path: full_path)
      end
    end
  end
end
