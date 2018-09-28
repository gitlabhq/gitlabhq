# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    # Ensures services which previously recieved all notes events continue
    # to recieve confidential ones.
    class SetConfidentialNoteEventsOnServices
      class Service < ActiveRecord::Base
        self.table_name = 'services'

        include ::EachBatch

        def self.services_to_update
          where(confidential_note_events: nil, note_events: true)
        end
      end

      def perform(start_id, stop_id)
        Service.services_to_update
               .where(id: start_id..stop_id)
               .update_all(confidential_note_events: true)
      end
    end
  end
end
