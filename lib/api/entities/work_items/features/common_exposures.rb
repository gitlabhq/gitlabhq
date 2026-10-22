# frozen_string_literal: true

module API
  module Entities
    module WorkItems
      module Features
        module CommonExposures
          extend ActiveSupport::Concern
          include ConditionalExposureHelpers

          included do
            expose_feature :description,
              using: ::API::Entities::WorkItems::Features::Description,
              documentation: { type: 'Entities::WorkItems::Features::Description' },
              expose_nil: true

            expose_feature :assignees,
              using: ::API::Entities::UserBasic,
              documentation: { type: 'Entities::UserBasic', is_array: true },
              &:assignees

            expose_feature :labels,
              using: ::API::Entities::WorkItems::Features::Labels,
              documentation: { type: 'Entities::WorkItems::Features::Labels' },
              expose_nil: true

            expose_feature :milestone,
              using: ::API::Entities::Milestone,
              documentation: { type: 'Entities::Milestone' },
              expose_nil: true,
              &:milestone

            expose_feature :start_and_due_date,
              using: ::API::Entities::WorkItems::Features::StartAndDueDate,
              documentation: { type: 'Entities::WorkItems::Features::StartAndDueDate' },
              expose_nil: true

            expose_feature :designs,
              using: ::API::Entities::WorkItems::Features::Designs,
              documentation: { type: 'Entities::WorkItems::Features::Designs' },
              expose_nil: true

            expose_feature :time_tracking,
              using: ::API::Entities::WorkItems::Features::TimeTracking,
              documentation: { type: 'Entities::WorkItems::Features::TimeTracking' },
              expose_nil: true

            expose_feature :error_tracking,
              using: ::API::Entities::WorkItems::Features::ErrorTracking,
              documentation: { type: 'Entities::WorkItems::Features::ErrorTracking' },
              expose_nil: true

            expose_feature :hierarchy,
              using: ::API::Entities::WorkItems::Features::Hierarchy,
              documentation: { type: 'Entities::WorkItems::Features::Hierarchy' },
              expose_nil: true

            expose_feature :award_emoji,
              using: ::API::Entities::WorkItems::Features::AwardEmoji,
              documentation: { type: 'Entities::WorkItems::Features::AwardEmoji' },
              expose_nil: true

            expose_feature :development,
              using: ::API::Entities::WorkItems::Features::Development,
              documentation: { type: 'Entities::WorkItems::Features::Development' },
              expose_nil: true

            expose_feature :notifications,
              using: ::API::Entities::WorkItems::Features::Notifications,
              documentation: { type: 'Entities::WorkItems::Features::Notifications' },
              expose_nil: true
          end
        end
      end
    end
  end
end
