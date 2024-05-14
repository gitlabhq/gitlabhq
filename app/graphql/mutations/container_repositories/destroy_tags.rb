# frozen_string_literal: true

module Mutations
  module ContainerRepositories
    class DestroyTags < ::Mutations::ContainerRepositories::DestroyBase
      graphql_name 'DestroyContainerRepositoryTags'

      LIMIT = 20
      TOO_MANY_TAGS_ERROR_MESSAGE = "Number of tags is greater than #{LIMIT}"

      authorize :destroy_container_image

      argument :id,
        ::Types::GlobalIDType[::ContainerRepository],
        required: true,
        description: 'ID of the container repository.'

      argument :tag_names,
        [GraphQL::Types::String],
        required: true,
        description: "Container repository tag(s) to delete. Total number can't be greater than #{LIMIT}",
        prepare: ->(tag_names, _) do
          raise Gitlab::Graphql::Errors::ArgumentError, TOO_MANY_TAGS_ERROR_MESSAGE if tag_names.size > LIMIT

          tag_names
        end

      field :deleted_tag_names,
        [GraphQL::Types::String],
        description: 'Deleted container repository tags.',
        null: false

      def resolve(id:, tag_names:)
        container_repository = authorized_find!(id: id)

        result = ::Projects::ContainerRepository::DeleteTagsService
          .new(container_repository.project, current_user, tags: tag_names)
          .execute(container_repository)

        track_event(:delete_tag_bulk, :tag) if result[:status] == :success

        {
          errors: Array(result[:message]),
          deleted_tag_names: result[:deleted] || []
        }
      end
    end
  end
end
