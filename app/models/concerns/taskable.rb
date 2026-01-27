# frozen_string_literal: true

# Contains functionality for objects that can have task lists in their
# descriptions.  Task list items can be added with Markdown like "* [x] Fix
# bugs".
#
# Used by MergeRequest and Issue
module Taskable
  # Model class for task items returned by Taskable.get_tasks, Taskable.get_updated_tasks, and
  # #task_list_items on classes included by Taskable.
  #
  # "complete?" is whether the item is marked complete (checked) or not.
  #
  # "text" is the human-friendly text relevant to the task item. It's used in
  # SystemNotes::IssuablesService to create system notes about checking or unchecking items.
  #
  # "source" is the HTML source relevant to the task item. It's used in .get_updated_tasks to
  # determine whether a task that was checked or unchecked hasn't otherwise changed. Depending on
  # the kind of task item (task list vs. task table), it might take different forms, and shouldn't
  # be presented to the user or otherwise stored.
  Item = Struct.new(:complete?, :text, :source, keyword_init: true)

  COMPLETED          = 'completed'
  INCOMPLETE         = 'incomplete'
  COMPLETE_PATTERN   = /\[[xX]\]/
  INCOMPLETE_PATTERN = /\[[[:space:]]\]/

  # Used by WorkItems::TaskListReferenceReplacementService.
  # Do not add new uses.
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

  def self.get_tasks(content)
    doc = Banzai::Pipeline::PlainMarkdownPipeline.call(content, {})[:output]

    items = []
    doc.xpath(Banzai::Filter::TaskListFilter::XPATH).each do |node|
      next if node.has_attribute?('data-inapplicable')

      text = Banzai::Filter::TaskListFilter.text_for_task_item_from_input(node)
      text = text.split('\n').first&.strip || ''

      source = Banzai::Filter::TaskListFilter.text_html_for_task_item_from_input(node)

      items << Taskable::Item.new(
        complete?: node.has_attribute?('checked'),
        text: text,
        source: source)
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

  def complete_task_list_item_count
    task_list_items.count(&:complete?)
  end

  # Return true if this object's description has any task list items.
  def tasks?
    task_list_items.any?
  end

  # Return a string that describes the current state of this Taskable's task
  # list items, e.g. "12 of 20 checklist items completed"
  def task_status(short: false)
    return '' if description.blank?

    checklist_item_noun = n_('checklist item', 'checklist items', task_list_items.count)
    if short
      format(s_('Tasks|%{complete_count}/%{total_count} %{checklist_item_noun}'),
        checklist_item_noun: checklist_item_noun,
        complete_count: complete_task_list_item_count,
        total_count: task_list_items.count)
    else
      format(s_('Tasks|%{complete_count} of %{total_count} %{checklist_item_noun} completed'),
        checklist_item_noun: checklist_item_noun,
        complete_count: complete_task_list_item_count,
        total_count: task_list_items.count)
    end
  end

  # Return a short string that describes the current state of this Taskable's
  # task list items -- for small screens
  def task_status_short
    task_status(short: true)
  end

  def task_completion_status
    @task_completion_status ||= {
      count: task_list_items.count,
      completed_count: complete_task_list_item_count
    }
  end
end
