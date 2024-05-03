# frozen_string_literal: true

module Mutations
  module Achievements
    class Create < BaseMutation
      graphql_name 'AchievementsCreate'

      include Gitlab::Graphql::Authorize::AuthorizeResource

      field :achievement,
        ::Types::Achievements::AchievementType,
        null: true,
        description: 'Achievement created.'

      argument :namespace_id, ::Types::GlobalIDType[::Namespace],
        required: true,
        description: 'Namespace for the achievement.'

      argument :name, GraphQL::Types::String,
        required: true,
        description: 'Name for the achievement.'

      argument :avatar, ApolloUploadServer::Upload,
        required: false,
        description: 'Avatar for the achievement.'

      argument :description, GraphQL::Types::String,
        required: false,
        description: 'Description of or notes for the achievement.'

      authorize :admin_achievement

      def resolve(args)
        namespace = authorized_find!(id: args[:namespace_id])

        raise Gitlab::Graphql::Errors::ResourceNotAvailable, '`achievements` feature flag is disabled.' \
          if Feature.disabled?(:achievements, namespace)

        result = ::Achievements::CreateService.new(namespace: namespace,
          current_user: current_user,
          params: args).execute
        { achievement: result.payload, errors: result.errors }
      end
    end
  end
end
