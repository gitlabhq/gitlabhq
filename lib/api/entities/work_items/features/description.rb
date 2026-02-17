# frozen_string_literal: true

module API
  module Entities
    module WorkItems
      module Features
        class Description < Grape::Entity
          expose :description,
            documentation: { type: 'String', example: 'Repellendus impedit et vel velit dignissimos.' },
            expose_nil: true
          expose :description_html,
            documentation: { type: 'String', example: '<p>Repellendus impedit et vel velit dignissimos.</p>' },
            expose_nil: true
          expose :edited?, as: :edited,
            documentation: { type: 'Boolean', example: false }
          expose :last_edited_at,
            documentation: { type: 'DateTime', example: '2022-11-15T08:30:55.232Z' },
            expose_nil: true
          expose :last_edited_by, using: ::API::Entities::UserBasic,
            documentation: { type: 'Entities::UserBasic' },
            expose_nil: true
          expose :task_completion_status,
            using: ::API::Entities::TaskCompletionStatus,
            documentation: { type: 'Entities::TaskCompletionStatus' }
        end
      end
    end
  end
end
