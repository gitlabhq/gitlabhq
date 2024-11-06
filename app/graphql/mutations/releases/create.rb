# frozen_string_literal: true

module Mutations
  module Releases
    class Create < Base
      graphql_name 'ReleaseCreate'

      field :release,
        Types::ReleaseType,
        null: true,
        description: 'Release after mutation.'

      argument :tag_name, GraphQL::Types::String,
        required: true, as: :tag,
        description: 'Name of the tag to associate with the release.'

      argument :tag_message, GraphQL::Types::String,
        required: false,
        description: 'Message to use if creating a new annotated tag.'

      argument :ref, GraphQL::Types::String,
        required: false,
        description: 'Commit SHA or branch name to use if creating a new tag.'

      argument :name, GraphQL::Types::String,
        required: false,
        description: 'Name of the release.'

      argument :description, GraphQL::Types::String,
        required: false,
        description: 'Description (also known as "release notes") of the release.'

      argument :released_at, Types::TimeType,
        required: false,
        description: 'Date and time for the release. Defaults to the current time. Expected in ISO 8601 format ' \
          '(`2019-03-15T08:00:00Z`). Only provide this field if creating an upcoming or historical release.'

      argument :milestones, [GraphQL::Types::String],
        required: false,
        description: 'Title of each milestone the release is associated with. ' \
          'GitLab Premium customers can specify group milestones.'

      argument :assets, Types::ReleaseAssetsInputType,
        required: false,
        description: 'Assets associated to the release.'

      authorize :create_release

      def resolve(project_path:, assets: nil, **scalars)
        project = authorized_find!(project_path)

        params = {
          **scalars,
          assets: assets.to_h
        }.with_indifferent_access

        result = ::Releases::CreateService.new(project, current_user, params).execute

        if result[:status] == :success
          {
            release: result[:release],
            errors: []
          }
        else
          {
            release: nil,
            errors: [result[:message]]
          }
        end
      end
    end
  end
end
