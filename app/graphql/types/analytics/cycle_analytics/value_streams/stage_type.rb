# frozen_string_literal: true

module Types
  module Analytics
    module CycleAnalytics
      module ValueStreams
        # rubocop: disable Graphql/AuthorizeTypes -- # Already authorized in parent value stream type.
        class StageType < BaseObject
          graphql_name 'ValueStreamStage'

          field :name,
            GraphQL::Types::String,
            null: false,
            description: 'Name of the stage.'

          field :hidden,
            GraphQL::Types::Boolean,
            null: false,
            description: 'Whether the stage is hidden.'

          field :custom,
            GraphQL::Types::Boolean,
            null: false,
            description: 'Whether the stage is customized.'

          field :start_event_identifier,
            StageEventEnum,
            null: false,
            description: 'Start event identifier.'

          field :end_event_identifier,
            StageEventEnum,
            null: false,
            description: 'End event identifier.'

          def start_event_identifier
            events_enum[object.start_event_identifier]
          end

          def end_event_identifier
            events_enum[object.end_event_identifier]
          end

          def events_enum
            Gitlab::Analytics::CycleAnalytics::StageEvents.to_enum.with_indifferent_access
          end
        end
        # rubocop: enable Graphql/AuthorizeTypes
      end
    end
  end
end

Types::Analytics::CycleAnalytics::ValueStreams::StageType.prepend_mod
