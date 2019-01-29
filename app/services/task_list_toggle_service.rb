# frozen_string_literal: true

# Finds the correct checkbox in the passed in markdown/html and toggles it's state,
# returning the updated markdown/html.
# We don't care if the text has changed above or below the specific checkbox, as long
# the checkbox still exists at exactly the same line number and the text is equal.
# If successful, new values are available in `updated_markdown` and `updated_markdown_html`
#
# Note: once we've removed RedCarpet support, we can remove the `index` and `sourcepos`
# parameters
class TaskListToggleService
  attr_reader :updated_markdown, :updated_markdown_html

  def initialize(markdown, markdown_html, line_source:, line_number:, toggle_as_checked:, index:, sourcepos: true)
    @markdown, @markdown_html  = markdown, markdown_html
    @line_source, @line_number = line_source, line_number
    @toggle_as_checked         = toggle_as_checked
    @index, @use_sourcepos     = index, sourcepos

    @updated_markdown, @updated_markdown_html = nil
  end

  def execute
    return false unless markdown && markdown_html

    !!(toggle_markdown && toggle_markdown_html)
  end

  private

  attr_reader :markdown, :markdown_html, :index, :toggle_as_checked
  attr_reader :line_source, :line_number, :use_sourcepos

  def toggle_markdown
    source_lines      = markdown.split("\n")
    source_line_index = line_number - 1
    markdown_task     = source_lines[source_line_index]

    return unless markdown_task == line_source
    return unless source_checkbox = Taskable::ITEM_PATTERN.match(markdown_task)

    currently_checked = TaskList::Item.new(source_checkbox[1]).complete?

    # Check `toggle_as_checked` to make sure we don't accidentally replace
    # any `[ ]` or `[x]` in the middle of the text
    if currently_checked
      markdown_task.sub!(Taskable::COMPLETE_PATTERN, '[ ]') unless toggle_as_checked
    else
      markdown_task.sub!(Taskable::INCOMPLETE_PATTERN, '[x]') if toggle_as_checked
    end

    source_lines[source_line_index] = markdown_task
    @updated_markdown = source_lines.join("\n")
  end

  def toggle_markdown_html
    html          = Nokogiri::HTML.fragment(markdown_html)
    html_checkbox = get_html_checkbox(html)
    return unless html_checkbox

    if toggle_as_checked
      html_checkbox[:checked] = 'checked'
    else
      html_checkbox.remove_attribute('checked')
    end

    @updated_markdown_html = html.to_html
  end

  # When using CommonMark, we should be able to use the embedded `sourcepos` attribute to
  # target the exact line in the DOM.  For RedCarpet, we need to use the index of the checkbox
  # that was checked and match it with what we think is the same checkbox.
  # The reason `sourcepos` is slightly more reliable is the case where a line of text is
  # changed from a regular line into a checkbox (or vice versa).  Then the checked index
  # in the UI will be off from the list of checkboxes we've calculated locally.
  # It's a rare circumstance, but since we can account for it, we do.
  def get_html_checkbox(html)
    if use_sourcepos
      html.css(".task-list-item[data-sourcepos^='#{line_number}:'] > input.task-list-item-checkbox").first
    else
      html.css('.task-list-item-checkbox')[index - 1]
    end
  end
end
