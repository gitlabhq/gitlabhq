# frozen_string_literal: true

module API
  module Entities
    class Event < Grape::Entity
      expose :id
      expose :project_id, :action_name
      expose :target_id, :target_iid, :target_type, :author_id
      expose :target_title
      expose :created_at
      expose :note, using: Entities::Note, if: ->(event, options) { event.note? }
      expose :author, using: Entities::UserBasic, if: ->(event, options) { event.author }
      expose :wiki_page, using: Entities::WikiPageBasic, if: ->(event, _options) { event.wiki_page? }

      expose :push_event_payload,
        as: :push_data,
        using: Entities::PushEventPayload,
        if: -> (event, _) { event.push_action? }

      expose :author_username do |event, options|
        event.author&.username
      end
    end
  end
end
