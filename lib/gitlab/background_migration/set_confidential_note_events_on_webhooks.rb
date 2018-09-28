# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    # Ensures hooks which previously recieved all notes events continue
    # to recieve confidential ones.
    class SetConfidentialNoteEventsOnWebhooks
      class WebHook < ActiveRecord::Base
        self.table_name = 'web_hooks'

        include ::EachBatch

        def self.hooks_to_update
          where(confidential_note_events: nil, note_events: true)
        end
      end

      def perform(start_id, stop_id)
        WebHook.hooks_to_update
               .where(id: start_id..stop_id)
               .update_all(confidential_note_events: true)
      end
    end
  end
end
