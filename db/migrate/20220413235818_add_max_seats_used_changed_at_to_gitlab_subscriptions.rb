# frozen_string_literal: true

class AddMaxSeatsUsedChangedAtToGitlabSubscriptions < Gitlab::Database::Migration[2.0]
  def change
    add_column :gitlab_subscriptions, :max_seats_used_changed_at, :datetime_with_timezone
  end
end
