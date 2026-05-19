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
              widget_name: :description,
              using: ::API::Entities::WorkItems::Features::Description,
              documentation: { type: 'Entities::WorkItems::Features::Description' },
              expose_nil: true

            expose_feature :assignees,
              widget_name: :assignees,
              using: ::API::Entities::UserBasic,
              documentation: { type: 'Entities::UserBasic', is_array: true },
              &:assignees

            expose_feature :labels,
              widget_name: :labels,
              using: ::API::Entities::WorkItems::Features::Labels,
              documentation: { type: 'Entities::WorkItems::Features::Labels' },
              expose_nil: true

            expose_feature :milestone,
              widget_name: :milestone,
              using: ::API::Entities::Milestone,
              documentation: { type: 'Entities::Milestone' },
              expose_nil: true,
              &:milestone

            expose_feature :start_and_due_date,
              widget_name: :start_and_due_date,
              using: ::API::Entities::WorkItems::Features::StartAndDueDate,
              documentation: { type: 'Entities::WorkItems::Features::StartAndDueDate' },
              expose_nil: true

            expose_feature :designs,
              widget_name: :designs,
              using: ::API::Entities::WorkItems::Features::Designs,
              documentation: { type: 'Entities::WorkItems::Features::Designs' },
              expose_nil: true

            expose_feature :time_tracking,
              widget_name: :time_tracking,
              using: ::API::Entities::WorkItems::Features::TimeTracking,
              documentation: { type: 'Entities::WorkItems::Features::TimeTracking' },
              expose_nil: true

            expose_feature :error_tracking,
              widget_name: :error_tracking,
              using: ::API::Entities::WorkItems::Features::ErrorTracking,
              documentation: { type: 'Entities::WorkItems::Features::ErrorTracking' },
              expose_nil: true

            expose_feature :hierarchy,
              widget_name: :hierarchy,
              using: ::API::Entities::WorkItems::Features::Hierarchy,
              documentation: { type: 'Entities::WorkItems::Features::Hierarchy' },
              expose_nil: true
          end
        end
      end
    end
  end
end
