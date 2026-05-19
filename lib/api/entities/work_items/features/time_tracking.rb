# frozen_string_literal: true

module API
  module Entities
    module WorkItems
      module Features
        class TimeTracking < Grape::Entity
          class HumanReadableAttributes < Grape::Entity
            expose :human_time_estimate, as: :time_estimate,
              documentation: { type: 'String', example: '3h 30m' },
              expose_nil: true
            expose :human_total_time_spent, as: :total_time_spent,
              documentation: { type: 'String', example: '1h 15m' },
              expose_nil: true do |widget|
              Gitlab::TimeTrackingFormatter.output(widget.timelogs.sum(&:time_spent))
            end
          end

          class Timelog < Grape::Entity
            expose :id,
              documentation: { type: 'Integer', example: 1 }
            expose :spent_at,
              documentation: { type: 'DateTime', example: '2024-01-15T10:00:00.000Z' },
              expose_nil: true do |timelog|
                timelog.spent_at || timelog.created_at
              end
            expose :time_spent,
              documentation: { type: 'Integer', example: 3600 }
            expose :user,
              using: ::API::Entities::UserBasic,
              documentation: { type: 'Entities::UserBasic' }
            expose :summary,
              documentation: { type: 'String', example: 'Reviewed MR' },
              expose_nil: true
          end

          expose :time_estimate,
            documentation: { type: 'Integer', example: 12600 },
            expose_nil: true
          expose :total_time_spent,
            documentation: { type: 'Integer', example: 4500 },
            expose_nil: true do |widget|
            widget.timelogs.sum(&:time_spent)
          end
          expose :human_readable_attributes,
            using: ::API::Entities::WorkItems::Features::TimeTracking::HumanReadableAttributes,
            documentation: { type: 'Entities::WorkItems::Features::TimeTracking::HumanReadableAttributes' },
            expose_nil: true do |widget|
              widget
            end
          expose :timelogs,
            using: ::API::Entities::WorkItems::Features::TimeTracking::Timelog,
            documentation: { type: 'Entities::WorkItems::Features::TimeTracking::Timelog', is_array: true }
        end
      end
    end
  end
end
