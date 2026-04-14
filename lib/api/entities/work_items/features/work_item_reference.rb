# frozen_string_literal: true

module API
  module Entities
    module WorkItems
      module Features
        class WorkItemReference < Grape::Entity
          expose :id,
            documentation: { type: 'Integer', example: 1 }

          expose :global_id,
            documentation: { type: 'String', example: 'gid://gitlab/WorkItem/1' } do |work_item|
            work_item.to_gid.to_s
          end

          expose :iid,
            documentation: { type: 'Integer', example: 42 }

          expose :title,
            documentation: { type: 'String', example: 'Plan first milestone' }

          expose :state,
            documentation: { type: 'String', example: 'opened' }

          expose :confidential,
            documentation: { type: 'Boolean', example: false }

          expose :work_item_type,
            using: ::API::Entities::WorkItems::Type,
            documentation: { type: 'Entities::WorkItems::Type' },
            expose_nil: true

          expose :reference,
            documentation: { type: 'String', example: 'gitlab-org/example#42' } do |work_item|
            work_item.to_reference(full: true)
          end

          expose :web_url,
            documentation: {
              type: 'String',
              example: 'https://gitlab.example.com/groups/example/-/work_items/42'
            } do |work_item|
            Gitlab::UrlBuilder.build(work_item)
          end

          expose :web_path,
            documentation: { type: 'String', example: '/groups/example/-/work_items/42' } do |work_item|
            Gitlab::UrlBuilder.build(work_item, only_path: true)
          end
        end
      end
    end
  end
end
