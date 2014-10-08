# Contains functionality for objects that can have task lists in their
# descriptions.  Task list items can be added with Markdown like "* [x] Fix
# bugs".
#
# Used by MergeRequest and Issue
module Taskable
  TASK_PATTERN_MD = /^(?<bullet> *[*-] *)\[(?<checked>[ xX])\]/.freeze
  TASK_PATTERN_HTML = /^<li>\[(?<checked>[ xX])\]/.freeze

  # Change the state of a task list item for this Taskable.  Edit the object's
  # description by finding the nth task item and changing its checkbox
  # placeholder to "[x]" if +checked+ is true, or "[ ]" if it's false.
  # Note: task numbering starts with 1
  def update_nth_task(n, checked)
    index = 0
    check_char = checked ? 'x' : ' '

    # Do this instead of using #gsub! so that ActiveRecord detects that a field
    # has changed.
    self.description = self.description.gsub(TASK_PATTERN_MD) do |match|
      index += 1
      case index
      when n then "#{$LAST_MATCH_INFO[:bullet]}[#{check_char}]"
      else match
      end
    end

    save
  end

  # Return true if this object's description has any task list items.
  def tasks?
    description && description.match(TASK_PATTERN_MD)
  end

  # Return a string that describes the current state of this Taskable's task
  # list items, e.g. "20 tasks (12 done, 8 unfinished)"
  def task_status
    return nil unless description

    num_tasks = 0
    num_done = 0

    description.scan(TASK_PATTERN_MD) do
      num_tasks += 1
      num_done += 1 unless $LAST_MATCH_INFO[:checked] == ' '
    end

    "#{num_tasks} tasks (#{num_done} done, #{num_tasks - num_done} unfinished)"
  end
end
