# frozen_string_literal: true

module Types
  module Achievements
    class AchievementType < BaseObject
      graphql_name 'Achievement'

      connection_type_class Types::CountableConnectionType

      authorize :read_achievement

      field :id,
        ::Types::GlobalIDType[::Achievements::Achievement],
        null: false,
        description: 'ID of the achievement.'

      field :namespace,
        ::Types::NamespaceType,
        description: 'Namespace of the achievement.'

      field :name,
        GraphQL::Types::String,
        null: false,
        description: 'Name of the achievement.'

      field :avatar_url,
        GraphQL::Types::String,
        null: true,
        description: 'URL to avatar of the achievement.'

      field :description,
        GraphQL::Types::String,
        null: true,
        description: 'Description or notes for the achievement.'

      field :created_at,
        Types::TimeType,
        null: false,
        description: 'Timestamp the achievement was created.'

      field :updated_at,
        Types::TimeType,
        null: false,
        description: 'Timestamp the achievement was last updated.'

      field :user_achievements,
        Types::Achievements::UserAchievementType.connection_type,
        null: true,
        experiment: { milestone: '15.10' },
        description: "Recipients for the achievement.",
        extras: [:lookahead],
        resolver: ::Resolvers::Achievements::UserAchievementsResolver

      def avatar_url
        object.avatar_url(only_path: false)
      end
    end
  end
end
