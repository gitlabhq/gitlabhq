# frozen_string_literal: true

# Finds the correct checkbox in the passed in markdown/html and toggles it's state,
# returning the updated markdown/html
# We don't care if the text has changed above or below the specific checkbox, as long
# the checkbox still exists at exactly the same line number and the text is equal
# If successful, new values are available in `updated_markdown` and `updated_markdown_html`
class TaskListToggleService
  attr_reader :updated_markdown, :updated_markdown_html

  def initialize(markdown, markdown_html, index:, currently_checked:, line_source:, line_number:)
    @markdown, @markdown_html  = markdown, markdown_html
    @index, @currently_checked = index, currently_checked
    @line_source, @line_number = line_source, line_number

    @updated_markdown, @updated_markdown_html = nil
  end

  def execute
    return false unless markdown && markdown_html

    !!(toggle_markdown && toggle_html)
  end

  private

  attr_reader :markdown, :markdown_html, :index, :currently_checked, :line_source, :line_number

  def toggle_markdown
    source_lines  = markdown.split("\n")
    markdown_task = source_lines[line_number - 1]

    return unless markdown_task == line_source
    return unless source_checkbox = Taskable::ITEM_PATTERN.match(markdown_task)

    if TaskList::Item.new(source_checkbox[1]).complete?
      markdown_task.sub!(Taskable::COMPLETE_PATTERN, '[ ]') if currently_checked
    else
      markdown_task.sub!(Taskable::INCOMPLETE_PATTERN, '[x]') unless currently_checked
    end

    source_lines[line_number - 1] = markdown_task
    @updated_markdown = source_lines.join("\n")
  end

  def toggle_html
    html          = Nokogiri::HTML.fragment(markdown_html)
    html_checkbox = html.css('.task-list-item-checkbox')[index - 1]
    # html_checkbox = html.css(".task-list-item[data-sourcepos^='#{changed_line_number}:'] > input.task-list-item-checkbox").first
    return unless html_checkbox

    if currently_checked
      html_checkbox.remove_attribute('checked')
    else
      html_checkbox[:checked] = 'checked'
    end

    @updated_markdown_html = html.to_html
  end
end
