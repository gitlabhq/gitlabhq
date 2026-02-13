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
    @sourcepos_adjust = 0

    @updated_markdown, @updated_markdown_html = nil
  end

  def execute
    return false unless markdown && markdown_html && line_sourcepos

    toggle_markdown && toggle_markdown_html
  end

  private

  attr_reader :markdown, :markdown_html, :line_source, :line_sourcepos, :toggle_as_checked, :sourcepos_adjust

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

    # Avoid underflow if given an unrealistic start column (task item symbol can't be at byte 0,
    # since the '[' character must come before it).
    return if sourcepos[:start][:column] == 0

    # Sourcepos is byte-based, so we must juggle bytes and Unicode "characters" (in the Ruby sense)
    # with care. Take the bytes up until (but not including any of) the start column, and then count
    # the characters in it for subsequent string operations.
    chars_before = line.byteslice(0...sourcepos[:start][:column] - 1).length

    line_before = line[0...chars_before]
    # We explicitly want to take three *characters* for line_item.
    line_item   = line[chars_before...chars_before + 3]
    line_after  = line[chars_before + 3..]

    return unless line_item

    if line_item.match?(Taskable::INCOMPLETE_PATTERN)
      if toggle_as_checked
        line = "#{line_before}[x]#{line_after}"

        # Edge case: if the original line_item contained a Unicode whitespace wider than
        # one byte, we need to:
        #
        # a) adjust the end checkbox sourcepos of the target, and
        # b) adjust the start and end of any following checkboxes' sourcepos on the same line,
        #
        # to account for the fact that we've removed one or more bytes in this replacement, and
        # sourcepos is byte-oriented (so we'd no longer actually match anything on subsequent
        # updates!).
        #
        # We adjust the positions mentioned above by the number of bytes in line_item minus 3,
        # 3 being the number of bytes we've replaced it with.
        #
        # Thus for a regular whitespace we have 3 bytes:
        #   0x5B '[', 0x20 ' ', 0x5D ']'  (3 - 3 = 0)
        # For e.g. U+00A0 NO-BREAK SPACE, we have 4 bytes:
        #   0x5B '[', 0xC2 0xA0 (NO-BREAK SPACE), 0x5D ']'  (4 - 3 = 1)
        #
        # The same never happens in reverse, when unchecking, since we only accept single-byte
        # characters ('x' and 'X') as task item "check" symbols, and we always replace it with a
        # plain single-byte space.
        @sourcepos_adjust = line_item.bytesize - 3
      end

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

    if @sourcepos_adjust > 0
      # Adjust end checkbox sourcepos of the target.
      html_checkbox['data-checkbox-sourcepos'] = self.class.render_sourcepos(
        self.class.adjust_sourcepos(sourcepos, end: { column: -@sourcepos_adjust }))

      # Adjust start and end of any following checkboxes. We locate all checkboxes from the
      # same line with CSS, and then scope down to those checkboxes which follow manually.
      html.css("input.task-list-item-checkbox[data-checkbox-sourcepos^='#{sourcepos[:start][:line] + 1}:']").each do |c|
        c_sourcepos = Banzai::Filter::MarkdownFilter.parse_sourcepos(c['data-checkbox-sourcepos'])
        next unless c_sourcepos[:start][:column] > sourcepos[:start][:column]

        c['data-checkbox-sourcepos'] = self.class.render_sourcepos(
          self.class.adjust_sourcepos(
            c_sourcepos,
            start: { column: -@sourcepos_adjust },
            end: { column: -@sourcepos_adjust }))
      end
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
    # We don't look for table task items: they didn't exist prior to precise sourcepos, and
    # precise sourcepos is necessary to locate one unambiguously.
    html.css(".task-list-item[data-sourcepos^='#{sourcepos[:start][:line] + 1}:'] input.task-list-item-checkbox").first
  end

  def sourcepos_maybe_precise?
    sourcepos[:start][:line] == sourcepos[:end][:line] && sourcepos[:end][:column] >= sourcepos[:start][:column]
  end

  def sourcepos
    @sourcepos ||= Banzai::Filter::MarkdownFilter.parse_sourcepos(line_sourcepos)
  end

  class << self
    def adjust_sourcepos(sourcepos, **adjust)
      result = { start: sourcepos[:start].dup, end: sourcepos[:end].dup }
      result[:start][:line] += adjust[:start][:line] if adjust.dig(:start, :line)
      result[:start][:column] += adjust[:start][:column] if adjust.dig(:start, :column)
      result[:end][:line] += adjust[:end][:line] if adjust.dig(:end, :line)
      result[:end][:column] += adjust[:end][:column] if adjust.dig(:end, :column)
      result
    end

    def render_sourcepos(sourcepos)
      "#{sourcepos[:start][:line] + 1}:#{sourcepos[:start][:column] + 1}-" \
        "#{sourcepos[:end][:line] + 1}:#{sourcepos[:end][:column] + 1}"
    end
  end
end
