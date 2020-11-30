# frozen_string_literal: true

module Mutations
  module Releases
    class Create < Base
      graphql_name 'ReleaseCreate'

      field :release,
            Types::ReleaseType,
            null: true,
            description: 'The release after mutation'

      argument :tag_name, GraphQL::STRING_TYPE,
               required: true, as: :tag,
               description: 'Name of the tag to associate with the release'

      argument :ref, GraphQL::STRING_TYPE,
               required: false,
               description: 'The commit SHA or branch name to use if creating a new tag'

      argument :name, GraphQL::STRING_TYPE,
               required: false,
               description: 'Name of the release'

      argument :description, GraphQL::STRING_TYPE,
               required: false,
               description: 'Description (also known as "release notes") of the release'

      argument :released_at, Types::TimeType,
               required: false,
               description: 'The date when the release will be/was ready. Defaults to the current time.'

      argument :milestones, [GraphQL::STRING_TYPE],
               required: false,
               description: 'The title of each milestone the release is associated with. GitLab Premium customers can specify group milestones.'

      argument :assets, Types::ReleaseAssetsInputType,
               required: false,
               description: 'Assets associated to the release'

      authorize :create_release

      def resolve(project_path:, assets: nil, **scalars)
        project = authorized_find!(full_path: project_path)

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
