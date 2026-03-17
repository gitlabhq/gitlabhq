# frozen_string_literal: true

module API
  module Entities
    module WorkItems
      module Features
        class Entity < Grape::Entity
          include ConditionalExposureHelpers

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
        end
      end
    end
  end
end
