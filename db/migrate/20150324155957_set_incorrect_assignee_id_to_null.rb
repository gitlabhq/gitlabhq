class SetIncorrectAssigneeIdToNull < ActiveRecord::Migration
  def up
    execute "UPDATE issues SET assignee_id = NULL WHERE assignee_id = -1"
    execute "UPDATE merge_requests SET assignee_id = NULL WHERE assignee_id = -1"
  end
end
