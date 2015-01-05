# In 20140914145549_migrate_to_new_members_model.rb we forgot to set the
# created_at and updated_at times for new records in the 'members' table. This
# became a problem after commit c8e78d972a5a628870eefca0f2ccea0199c55bda which
# was added in GitLab 7.5. With this migration we ensure that all rows in
# 'members' have at least some created_at and updated_at timestamp.
class AddTimestampsToMembers < ActiveRecord::Migration
  def up
    execute "UPDATE members SET created_at = NOW() WHERE created_at is NULL"
    execute "UPDATE members SET updated_at = NOW() WHERE updated_at is NULL"
  end

  def down
    # no change
  end
end
