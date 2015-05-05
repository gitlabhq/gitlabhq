class RemoveAbandonedGroupMembersRecords < ActiveRecord::Migration
  def change
    execute("DELETE FROM members WHERE type = 'GroupMember' AND source_id NOT IN(\
        SELECT id FROM namespaces WHERE type='Group')")
  end
end
