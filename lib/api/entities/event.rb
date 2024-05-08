# frozen_string_literal: true

module API
  module Entities
    class Event < Grape::Entity
      expose :id, documentation: { type: 'integer', example: 1 }
      expose :project_id, documentation: { type: 'integer', example: 2 }
      expose :action_name, documentation: { type: 'string', example: 'closed' }
      expose :target_id, documentation: { type: 'integer', example: 160 }
      expose :target_iid, documentation: { type: 'integer', example: 157 }
      expose :target_type, documentation: { type: 'string', example: 'Issue' }
      expose :author_id, documentation: { type: 'integer', example: 25 }
      expose :target_title, documentation: { type: 'string', example: 'Public project search field' }
      expose :created_at, documentation: { type: 'string', example: '2017-02-09T10:43:19.667Z' }
      expose :note, using: Entities::Note, if: ->(event, options) { event.note? }
      expose :author, using: Entities::UserBasic, if: ->(event, options) { event.author }
      expose :wiki_page, using: Entities::WikiPageBasic, if: ->(event, _options) { event.wiki_page? }
      expose :imported?, as: :imported, documentation: { type: 'boolean', example: false }
      expose :imported_from, documentation: { type: 'string', example: 'none' }

      expose :push_event_payload,
        as: :push_data,
        using: Entities::PushEventPayload,
        if: ->(event, _) { event.push_action? }

      expose :author_username, documentation: { type: 'string', example: 'root' } do |event, options|
        event.author&.username
      end
    end
  end
end
