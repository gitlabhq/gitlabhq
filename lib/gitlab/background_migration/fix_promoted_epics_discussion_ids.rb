# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This migration updates discussion ids for epics that were promoted from issue so that the discussion id on epics
    # is different from discussion id on issue, which was causing problems when replying to epic discussions as it would
    # identify the discussion as related to an issue and complaint about missing project_id
    class FixPromotedEpicsDiscussionIds
      # notes model to iterate through the notes to be updated
      class Note < ActiveRecord::Base
        self.table_name = 'notes'
        self.inheritance_column = :_type_disabled
      end

      def perform(discussion_ids)
        Note.where(noteable_type: 'Epic')
          .where(discussion_id: discussion_ids)
          .update_all("discussion_id=MD5(discussion_id)||substring(discussion_id from 1 for 8)")
      end
    end
  end
end
