# rubocop:disable all
# 20141121133009_add_timestamps_to_members.rb was meant to ensure that all
# rows in the members table had created_at and updated_at set, following an
# error in a previous migration. This failed to set all rows in at least one
# case: https://gitlab.com/gitlab-org/gitlab-ce/issues/20568
#
# Why this happened is lost in the mists of time, so repeat the SQL query
# without speculation, just in case more than one person was affected.
class AddTimestampsToMembersAgain < ActiveRecord::Migration
  DOWNTIME = false

  def up
    execute "UPDATE members SET created_at = NOW() WHERE created_at IS NULL"
    execute "UPDATE members SET updated_at = NOW() WHERE updated_at IS NULL"
  end

  def down
    # no change
  end

end
