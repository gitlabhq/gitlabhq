# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      module TimeTracking
        # rubocop:disable Graphql/AuthorizeTypes -- we already authorize the work item itself
        class TimelogType < BaseObject
          graphql_name 'WorkItemTimelog'

          connection_type_class ::Types::TimeTracking::TimelogConnectionType
          expose_permissions ::Types::PermissionTypes::Timelog

          field :id, GraphQL::Types::ID,
            null: false,
            description: 'Internal ID of the timelog.'

          field :spent_at, ::Types::TimeType,
            null: true,
            description: 'Timestamp of when the time tracked was spent at.'

          field :time_spent, GraphQL::Types::Int,
            null: false,
            description: 'Time spent displayed in seconds.'

          field :user, ::Types::UserType,
            null: false,
            description: 'User that logged the time.'

          field :note, ::Types::Notes::NoteType,
            null: true,
            description: 'Note where the quick action was executed to add the logged time.'

          field :summary, GraphQL::Types::String,
            null: true,
            description: 'Summary of how the time was spent.'

          def user
            Gitlab::Graphql::Loaders::BatchModelLoader.new(User, object.user_id).find
          end

          def spent_at
            object.spent_at || object.created_at
          end
        end
        # rubocop:enable Graphql/AuthorizeTypes
      end
    end
  end
end
