# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Fixes notes with NULL discussion_ids due to a bug when importing from GitHub
    # Bug was fixed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/76517
    class BackfillNoteDiscussionId
      SUB_BATCH_SIZE = 300

      # Migration only version of notes model
      class Note < ApplicationRecord
        include EachBatch

        self.table_name = 'notes'

        # Based on https://gitlab.com/gitlab-org/gitlab/blob/117c14d0c79403e169cf52922b48f69d1dcf6a85/app/models/discussion.rb#L62-74
        def generate_discussion_id
          Digest::SHA1.hexdigest(
            [:discussion, noteable_type.try(:underscore), noteable_id || commit_id, SecureRandom.hex].join('-')
          )
        end
      end

      def perform(start_id, stop_id)
        notes = Note.select(:id, :noteable_type, :noteable_id, :commit_id)
                    .where(discussion_id: nil, id: start_id..stop_id)

        notes.each_batch(of: SUB_BATCH_SIZE) do |relation|
          update_discussion_ids(relation)
        end
      end

      private

      def update_discussion_ids(notes)
        mapping = notes.index_with do |note|
          { discussion_id: note.generate_discussion_id }
        end

        Gitlab::Database::BulkUpdate.execute(%i[discussion_id], mapping)
      end
    end
  end
end
