require 'task_list'
require 'task_list/filter'

# Contains functionality for objects that can have task lists in their
# descriptions.  Task list items can be added with Markdown like "* [x] Fix
# bugs".
#
# Used by MergeRequest and Issue
module Taskable
  # Called by `TaskList::Summary`
  def task_list_items
    return [] if description.blank?

    @task_list_items ||= description.scan(TaskList::Filter::ItemPattern).collect do |item|
      # ItemPattern strips out the hyphen, but Item requires it. Rabble rabble.
      TaskList::Item.new("- #{item}")
    end
  end

  def tasks
    @tasks ||= TaskList.new(self)
  end

  # Return true if this object's description has any task list items.
  def tasks?
    tasks.summary.items?
  end

  # Return a string that describes the current state of this Taskable's task
  # list items, e.g. "20 tasks (12 completed, 8 remaining)"
  def task_status
    return '' if description.blank?

    sum = tasks.summary
    "#{sum.item_count} tasks (#{sum.complete_count} completed, #{sum.incomplete_count} remaining)"
  end
end
