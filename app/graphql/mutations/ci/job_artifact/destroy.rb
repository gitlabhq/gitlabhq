# frozen_string_literal: true

module Mutations
  module Ci
    module JobArtifact
      class Destroy < BaseMutation
        graphql_name 'ArtifactDestroy'

        authorize :destroy_artifacts

        ArtifactID = ::Types::GlobalIDType[::Ci::JobArtifact]

        argument :id,
          ArtifactID,
          required: true,
          description: 'ID of the artifact to delete.'

        field :artifact,
          Types::Ci::JobArtifactType,
          null: true,
          description: 'Deleted artifact.'

        def find_object(id:)
          GlobalID::Locator.locate(id)
        end

        def resolve(id:)
          artifact = authorized_find!(id: id)

          if artifact.destroy
            { errors: [] }
          else
            { errors: artifact.errors.full_messages }
          end
        end
      end
    end
  end
end
