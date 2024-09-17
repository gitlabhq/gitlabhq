# frozen_string_literal: true

module Types
  module Analytics
    module CycleAnalytics
      module ValueStreams
        # rubocop: disable Graphql/AuthorizeTypes -- # Already authorized in parent.
        class StageItemsType < BaseObject
          graphql_name 'ValueStreamStageItems'

          include EntityDateHelper

          field :end_event_timestamp,
            Types::TimeType,
            null: true,
            description: 'When exited the stage.'

          field :duration,
            GraphQL::Types::String,
            null: true,
            description: 'Duration of the item on the stage.'

          field :record,
            ::Types::IssuableType,
            null: true,
            description: 'Item record.'

          def duration
            return unless object.total_time.present?

            duration_array = distance_of_time_as_hash(object.total_time.to_f).first

            duration_array.reverse.join(' ')
          end

          def record
            object
          end
        end
        # rubocop: enable Graphql/AuthorizeTypes
      end
    end
  end
end

Types::Analytics::CycleAnalytics::ValueStreams::StageItemsType.prepend_mod
