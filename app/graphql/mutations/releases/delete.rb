# frozen_string_literal: true

module Mutations
  module Releases
    class Delete < Base
      graphql_name 'ReleaseDelete'

      field :release,
        Types::ReleaseType,
        null: true,
        description: 'Deleted release.'

      argument :tag_name, GraphQL::Types::String,
        required: true, as: :tag,
        description: 'Name of the tag associated with the release to delete.'

      authorize :destroy_release

      def resolve(project_path:, tag:)
        project = authorized_find!(project_path)

        params = { tag: tag }.with_indifferent_access

        result = ::Releases::DestroyService.new(project, current_user, params).execute

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
