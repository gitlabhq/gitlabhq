# frozen_string_literal: true

# This service does its best to toggle a task item in GLFM based on the given source position,
# settings its state to toggle_as_checked.  A parallel method in the frontend is found in
# app/assets/javascripts/behaviors/markdown/utils.js.
#
# If the sourcepos range precisely identifies a valid task list symbol in the source, it is replaced
# exactly. This was added in our Markdown parser recently: https://github.com/kivikakk/comrak/pull/705.
#
# If not (such as for all cached Markdown renders), we assume it's the list item's sourcepos, and replace
# the first task item-looking sequence we find in the line.
#
# Note that, above and beyond what the frontend version does, we also update the rendered HTML.
# To maintain parity with what a full re-render would do, we take special care to update checkbox
# sourcepos (used to precisely identify updates within a line, crucial for task items in tables),
# particularly when Unicode whitespace is involved.
class TaskListToggleService
  attr_reader :updated_markdown, :updated_markdown_html

  def initialize(markdown, markdown_html, line_source:, line_sourcepos:, toggle_as_checked:)
    @markdown = markdown
    @markdown_html = markdown_html
    @line_source = line_source
    @line_sourcepos = line_sourcepos
    @toggle_as_checked = toggle_as_checked

    @updated_markdown, @updated_markdown_html = nil
  end

  def execute
    return false unless markdown && markdown_html && line_sourcepos

    toggle_markdown && toggle_markdown_html
  end

  private

  attr_reader :markdown, :markdown_html, :line_source, :line_sourcepos, :toggle_as_checked

  def toggle_markdown
    lines = markdown.split("\n")
    line  = lines[sourcepos[:start][:line]]

    # The source in the DB could be using either \n or \r\n line endings
    return unless line.chomp == line_source

    # Attempt precise sourcepos replacement, falling back to imprecise on failure
    # (replace first task item-looking thing on the line).
    changed_line = toggle_markdown_precise(line) ||
      line.sub(/\[(?:[[:space:]]|x|~)\]/i, toggle_as_checked ? '[x]' : '[ ]')

    return if changed_line == line

    lines[sourcepos[:start][:line]] = changed_line
    @updated_markdown = lines.join("\n")

    true
  end

  def toggle_markdown_precise(line)
    return unless sourcepos_maybe_precise?

    # Possibly precise sourcepos given; check that a task item does appear to be exactly there and set accordingly.
    # Return `line` (whether changed or unchanged) if we did match a checkbox at the target; otherwise
    # return nil and do an imprecise replacement.

    # Avoid underflow if given an unrealistic start column (task item symbol can't be at position 0,
    # since the '[' character must come before it).
    return if sourcepos[:start][:column] == 0

    line_before = line[0...sourcepos[:start][:column] - 1]
    line_item   = line[sourcepos[:start][:column] - 1...sourcepos[:start][:column] + 2]
    line_after  = line[sourcepos[:start][:column] + 2..]

    return unless line_item

    if line_item.match?(Taskable::INCOMPLETE_PATTERN)
      line = "#{line_before}[x]#{line_after}" if toggle_as_checked
      line
    elsif line_item.match?(Taskable::COMPLETE_PATTERN)
      line = "#{line_before}[ ]#{line_after}" unless toggle_as_checked
      line
    end
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

    true
  end

  def get_html_checkbox(html)
    get_html_checkbox_precise(html) ||
      get_html_checkbox_imprecise(html)
  end

  def get_html_checkbox_precise(html)
    return unless sourcepos_maybe_precise?

    html.css("input.task-list-item-checkbox[data-checkbox-sourcepos='#{line_sourcepos}']").first
  end

  def get_html_checkbox_imprecise(html)
    html.css(".task-list-item[data-sourcepos^='#{sourcepos[:start][:line] + 1}:'] input.task-list-item-checkbox").first
  end

  def sourcepos_maybe_precise?
    sourcepos[:start][:line] == sourcepos[:end][:line] && sourcepos[:end][:column] >= sourcepos[:start][:column]
  end

  def sourcepos
    @sourcepos ||= Banzai::Filter::MarkdownFilter.parse_sourcepos(line_sourcepos)
  end
end
