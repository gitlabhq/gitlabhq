# frozen_string_literal: true

class RemoveOrphanedInvitedMembers < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    # As of 2020-04-23, there are 19 entries on GitLab.com that match this criteria.
    execute "DELETE FROM members WHERE user_id IS NULL AND invite_token IS NULL AND invite_accepted_at IS NOT NULL"
  end

  def down
  end
end
