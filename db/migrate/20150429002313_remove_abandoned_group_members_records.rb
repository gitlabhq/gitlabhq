class RemoveAbandonedGroupMembersRecords < ActiveRecord::Migration
  def up
    execute("DELETE FROM members WHERE type = 'GroupMember' AND source_id NOT IN(\
        SELECT id FROM namespaces WHERE type='Group')")
  end

  def down
  end
end
