# frozen_string_literal: true

class AddTaskToWorkItemTypes < Gitlab::Database::Migration[1.0]
  TASK_ENUM_VALUE = 4

  class WorkItemType < ActiveRecord::Base
    self.inheritance_column = :_type_disabled
    self.table_name = 'work_item_types'

    validates :name, uniqueness: { case_sensitive: false, scope: [:namespace_id] }
  end

  def up
    # New instances will not run this migration and add this type via fixtures
    # checking if record exists mostly because migration specs will run all migrations
    # and that will conflict with the preloaded base work item types
    task_work_item = WorkItemType.find_by(name: 'Task', namespace_id: nil)

    if task_work_item
      say('Task item record exist, skipping creation')
    else
      WorkItemType.create(name: 'Task', namespace_id: nil, base_type: TASK_ENUM_VALUE, icon_name: 'issue-type-task')
    end
  end

  def down
    # There's the remote possibility that issues could already be
    # using this issue type, with a tight foreign constraint.
    # Therefore we will not attempt to remove any data.
  end
end
