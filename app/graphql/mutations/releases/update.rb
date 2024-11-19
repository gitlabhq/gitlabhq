# frozen_string_literal: true

module Mutations
  module Releases
    class Update < Base
      graphql_name 'ReleaseUpdate'

      field :release,
        Types::ReleaseType,
        null: true,
        description: 'Release after mutation.'

      argument :tag_name, GraphQL::Types::String,
        required: true, as: :tag,
        description: 'Name of the tag associated with the release.'

      argument :name, GraphQL::Types::String,
        required: false,
        description: 'Name of the release.'

      argument :description, GraphQL::Types::String,
        required: false,
        description: 'Description (release notes) of the release.'

      argument :released_at, Types::TimeType,
        required: false,
        description: 'Release date.'

      argument :milestones, [GraphQL::Types::String],
        required: false,
        description: 'Title of each milestone the release is associated with. ' \
          'GitLab Premium customers can specify group milestones.'

      authorize :update_release

      def ready?(**args)
        if args.key?(:released_at) && args[:released_at].nil?
          raise Gitlab::Graphql::Errors::ArgumentError,
            'if the releasedAt argument is provided, it cannot be null'
        end

        if args.key?(:milestones) && args[:milestones].nil?
          raise Gitlab::Graphql::Errors::ArgumentError,
            'if the milestones argument is provided, it cannot be null'
        end

        super
      end

      def resolve(project_path:, **scalars)
        project = authorized_find!(project_path)

        params = scalars.with_indifferent_access

        result = ::Releases::UpdateService.new(project, current_user, params).execute

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
