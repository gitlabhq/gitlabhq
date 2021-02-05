# frozen_string_literal: true

module Types
  class ContainerRepositoryDetailsType < Types::ContainerRepositoryType
    graphql_name 'ContainerRepositoryDetails'

    description 'Details of a container repository'

    authorize :read_container_image

    field :tags,
          Types::ContainerRepositoryTagType.connection_type,
          null: true,
          description: 'Tags of the container repository.',
          max_page_size: 20

    def can_delete
      Ability.allowed?(current_user, :destroy_container_image, object)
    end
  end
end
