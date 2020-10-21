# frozen_string_literal: true

class AddChangeReviewerMergeRequestToNotificationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :notification_settings, :change_reviewer_merge_request, :boolean
  end
end
