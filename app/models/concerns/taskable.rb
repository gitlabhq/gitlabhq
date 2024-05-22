# frozen_string_literal: true

require 'task_list'
require 'task_list/filter'

# Contains functionality for objects that can have task lists in their
# descriptions.  Task list items can be added with Markdown like "* [x] Fix
# bugs".
#
# Used by MergeRequest and Issue
module Taskable
  COMPLETED          = 'completed'
  INCOMPLETE         = 'incomplete'
  COMPLETE_PATTERN   = /\[[xX]\]/
  INCOMPLETE_PATTERN = /\[[[:space:]]\]/
  ITEM_PATTERN       = %r{
    ^
    (?:(?:>\s{0,4})*)               # optional blockquote characters
    ((?:\s*(?:[-+*]|(?:\d+[.)])))+) # list prefix (one or more) required - task item has to be always in a list
    \s+                             # whitespace prefix has to be always presented for a list item
    (                               # checkbox
      #{COMPLETE_PATTERN}|#{INCOMPLETE_PATTERN}
    )
    (\s.+)                          # followed by whitespace and some text.
  }x

  ITEM_PATTERN_UNTRUSTED =
    '^' \
    '(?:(?:>\s{0,4})*)' \
    '(?P<prefix>(?:\s*(?:[-+*]|(?:\d+[.)])))+)' \
    '\s+' \
    '(?P<checkbox>' \
    "#{COMPLETE_PATTERN.source}|#{INCOMPLETE_PATTERN.source}" \
    ')' \
    '(?P<label>\s.+)'.freeze

  # ignore tasks in code or html comment blocks.  HTML blocks
  # are ok as we allow tasks inside <detail> blocks
  REGEX =
    "#{::Gitlab::Regex.markdown_code_or_html_comments_untrusted}" \
    "|" \
    "(?P<task_item>" \
    "#{ITEM_PATTERN_UNTRUSTED}" \
    ")".freeze

  def self.get_tasks(content)
    items = []

    regex = Gitlab::UntrustedRegexp.new(REGEX, multiline: true)
    regex.scan(content.to_s).each do |match|
      next unless regex.extract_named_group(:task_item, match)

      prefix = regex.extract_named_group(:prefix, match)
      checkbox = regex.extract_named_group(:checkbox, match)
      label = regex.extract_named_group(:label, match)

      items << TaskList::Item.new("#{prefix.strip} #{checkbox}", label.strip)
    end

    items
  end

  def self.get_updated_tasks(old_content:, new_content:)
    old_tasks = get_tasks(old_content)
    new_tasks = get_tasks(new_content)

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
  # list items, e.g. "12 of 20 checklist items completed"
  def task_status(short: false)
    return '' if description.blank?

    sum = tasks.summary
    checklist_item_noun = n_('checklist item', 'checklist items', sum.item_count)
    if short
      format(s_('Tasks|%{complete_count}/%{total_count} %{checklist_item_noun}'),
        checklist_item_noun: checklist_item_noun, complete_count: sum.complete_count, total_count: sum.item_count)
    else
      format(s_('Tasks|%{complete_count} of %{total_count} %{checklist_item_noun} completed'),
        checklist_item_noun: checklist_item_noun, complete_count: sum.complete_count, total_count: sum.item_count)
    end
  end

  # Return a short string that describes the current state of this Taskable's
  # task list items -- for small screens
  def task_status_short
    task_status(short: true)
  end

  def task_completion_status
    @task_completion_status ||= {
      count: tasks.summary.item_count,
      completed_count: tasks.summary.complete_count
    }
  end
end
