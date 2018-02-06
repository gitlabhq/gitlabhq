require 'task_list'
require 'task_list/filter'

# Contains functionality for objects that can have task lists in their
# descriptions.  Task list items can be added with Markdown like "* [x] Fix
# bugs".
#
# Used by MergeRequest and Issue
module Taskable
  COMPLETED    = 'completed'.freeze
  INCOMPLETE   = 'incomplete'.freeze
  ITEM_PATTERN = %r{
    ^
    \s*(?:[-+*]|(?:\d+\.)) # list prefix required - task item has to be always in a list
    \s+                       # whitespace prefix has to be always presented for a list item
    (\[\s\]|\[[xX]\])         # checkbox
    (\s.+)                    # followed by whitespace and some text.
  }x

  def self.get_tasks(content)
    content.to_s.scan(ITEM_PATTERN).map do |checkbox, label|
      # ITEM_PATTERN strips out the hyphen, but Item requires it. Rabble rabble.
      TaskList::Item.new("- #{checkbox}", label.strip)
    end
  end

  def self.get_updated_tasks(old_content:, new_content:)
    old_tasks, new_tasks = get_tasks(old_content), get_tasks(new_content)

    new_tasks.select.with_index do |new_task, i|
      old_task = old_tasks[i]
      next unless old_task

      new_task.source == old_task.source && new_task.complete? != old_task.complete?
    end
  end

  # Called by `TaskList::Summary`
  def task_list_items
    return [] if description.blank?

    @task_list_items ||= Taskable.get_tasks(description) # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  def tasks
    @tasks ||= TaskList.new(self)
  end

  # Return true if this object's description has any task list items.
  def tasks?
    tasks.summary.items?
  end

  # Return a string that describes the current state of this Taskable's task
  # list items, e.g. "12 of 20 tasks completed"
  def task_status(short: false)
    return '' if description.blank?

    prep, completed = if short
                        ['/', '']
                      else
                        [' of ', ' completed']
                      end

    sum = tasks.summary
    "#{sum.complete_count}#{prep}#{sum.item_count} #{'task'.pluralize(sum.item_count)}#{completed}"
  end

  # Return a short string that describes the current state of this Taskable's
  # task list items -- for small screens
  def task_status_short
    task_status(short: true)
  end
end
