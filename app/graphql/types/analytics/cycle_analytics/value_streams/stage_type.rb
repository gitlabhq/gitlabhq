# frozen_string_literal: true

module Types
  module Analytics
    module CycleAnalytics
      module ValueStreams
        # rubocop: disable Graphql/AuthorizeTypes -- # Already authorized in parent value stream type.
        class StageType < BaseObject
          graphql_name 'ValueStreamStage'

          field :id,
            type: ::Types::GlobalIDType[::Analytics::CycleAnalytics::Stage],
            null: false,
            description: "ID of the value stream."

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

          field :start_event_html_description,
            GraphQL::Types::String,
            null: false,
            description: 'HTML description of the start event.'

          field :end_event_html_description,
            GraphQL::Types::String,
            null: false,
            description: 'HTML description of the end event.'

          field :metrics,
            Types::Analytics::CycleAnalytics::ValueStreams::StageMetricsType,
            null: false,
            resolver: Resolvers::Analytics::CycleAnalytics::ValueStreams::StageMetricsResolver,
            description: 'Aggregated metrics for the given stage'

          def start_event_identifier
            events_enum[object.start_event_identifier]
          end

          def end_event_identifier
            events_enum[object.end_event_identifier]
          end

          def start_event_html_description
            stage_entity.start_event_html_description
          end

          def end_event_html_description
            stage_entity.end_event_html_description
          end

          def events_enum
            Gitlab::Analytics::CycleAnalytics::StageEvents.to_enum.with_indifferent_access
          end

          def stage_entity
            @stage_entity ||= ::Analytics::CycleAnalytics::StageEntity.new(object)
          end
        end
        # rubocop: enable Graphql/AuthorizeTypes
      end
    end
  end
end

Types::Analytics::CycleAnalytics::ValueStreams::StageType.prepend_mod
