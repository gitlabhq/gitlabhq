# frozen_string_literal: true

# Finds the correct checkbox in the passed in markdown/html and toggles it's state,
# returning the updated markdown/html.
# We don't care if the text has changed above or below the specific checkbox, as long
# the checkbox still exists at exactly the same line number and the text is equal.
# If successful, new values are available in `updated_markdown` and `updated_markdown_html`
class TaskListToggleService
  attr_reader :updated_markdown, :updated_markdown_html

  def initialize(markdown, markdown_html, line_source:, line_number:, toggle_as_checked:)
    @markdown = markdown
    @markdown_html = markdown_html
    @line_source = line_source
    @line_number = line_number
    @toggle_as_checked = toggle_as_checked

    @updated_markdown, @updated_markdown_html = nil
  end

  def execute
    return false unless markdown && markdown_html

    toggle_markdown && toggle_markdown_html
  end

  private

  attr_reader :markdown, :markdown_html, :toggle_as_checked
  attr_reader :line_source, :line_number

  def toggle_markdown
    source_lines      = markdown.split("\n")
    source_line_index = line_number - 1
    markdown_task     = source_lines[source_line_index]

    # The source in the DB could be using either \n or \r\n line endings
    return unless markdown_task.chomp == line_source
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
  # target the exact line in the DOM.
  def get_html_checkbox(html)
    html.css(".task-list-item[data-sourcepos^='#{line_number}:'] input.task-list-item-checkbox").first
  end
end
