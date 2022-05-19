# frozen_string_literal: true

# This module contains a Ruby port of Python logic from the `get_tests` method of the
# `spec_test.py` script (see copy of original code in a comment at the bottom of this file):
# https://github.com/github/cmark-gfm/blob/5dfedc7/test/spec_tests.py#L82
#
# The logic and structure is as unchanged as possible from the original Python - no
# cleanup or refactoring was done.
#
# Changes from the original logic were made to follow Ruby/GitLab syntax, idioms, and linting rules.
#
# Additional logic was also added to:
# 1. Capture all nested headers, not just the most recent.
# 2. Raise an exception if an unexpected state is encountered.
#
# Comments indicate where changes or additions were made.
module Glfm
  module ParseExamples
    REGULAR_TEXT = 0
    MARKDOWN_EXAMPLE = 1
    HTML_OUTPUT = 2
    EXAMPLE_BACKTICKS_LENGTH = 32
    EXAMPLE_BACKTICKS_STRING = '`' * EXAMPLE_BACKTICKS_LENGTH

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def parse_examples(spec_txt_lines)
      line_number = 0
      start_line = 0
      example_number = 0
      markdown_lines = []
      html_lines = []
      state = REGULAR_TEXT # 0 regular text, 1 markdown example, 2 html output
      extensions = []
      headertext = '' # most recent header text
      headers = [] # all nested headers since last H2 - new logic compared to original Python code
      tests = []

      h1_regex = /\A# / # new logic compared to original Python code
      h2_regex = /\A## / # new logic compared to original Python code
      header_regex = /\A#+ / # Added beginning of line anchor to original Python code

      spec_txt_lines.each do |line|
        line_number += 1
        stripped_line = line.strip
        if stripped_line.start_with?("#{EXAMPLE_BACKTICKS_STRING} example")
          # If beginning line of an example block...
          state = MARKDOWN_EXAMPLE
          extensions = stripped_line[(EXAMPLE_BACKTICKS_LENGTH + " example".length)..].split
        elsif stripped_line == EXAMPLE_BACKTICKS_STRING
          # Else if end line of an example block...
          state = REGULAR_TEXT
          example_number += 1
          end_line = line_number
          unless extensions.include?('disabled')
            tests <<
              {
                markdown: markdown_lines.join.tr('→', "\t"),
                html: html_lines.join.tr('→', "\t"),
                example: example_number,
                start_line: start_line,
                end_line: end_line,
                section: headertext,
                extensions: extensions,
                headers: headers.dup # new logic compared to original Python code
              }
            start_line = 0
            markdown_lines = []
            html_lines = []
          end
        elsif stripped_line == "."
          # Else if the example divider line...
          state = HTML_OUTPUT
          # Else if we are currently in a markdown example...
        elsif state == MARKDOWN_EXAMPLE
          start_line = line_number - 1 if start_line == 0

          markdown_lines.append(line)
        elsif state == HTML_OUTPUT
          # Else if we are currently in the html output...
          html_lines.append(line)
        elsif state == REGULAR_TEXT && line =~ header_regex
          # Else if we are in regular text and it is a header line
          # NOTE: This assumes examples are only nested up to 2 levels deep (H2)

          # Extract the header text from the line
          headertext = line.gsub(header_regex, '').strip

          # reset the headers array if we found a new H1
          headers = [] if line =~ h1_regex # new logic compared to original Python code

          # pop the last entry from the headers array if we found a new H2
          headers.pop if headers.length == 2 && line =~ h2_regex # new logic compared to original Python code

          # push the new header text to the headers array
          headers << headertext # New logic compared to original Python code
        else
          # Else if we are in regular text...

          # This else block is new logic compared to original Python code

          # Sanity check for state machine
          raise 'Unexpected state encountered when parsing examples' unless state == REGULAR_TEXT

          # no-op - skips any other non-header regular text lines
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      tests
    end
  end
end

# Original `get_tests` method from spec_test.py:
# rubocop:disable Style/BlockComments
# rubocop:disable Style/AsciiComments
=begin
def get_tests(specfile):
    line_number = 0
    start_line = 0
    end_line = 0
    example_number = 0
    markdown_lines = []
    html_lines = []
    state = 0  # 0 regular text, 1 markdown example, 2 html output
    extensions = []
    headertext = ''
    tests = []

    header_re = re.compile('#+ ')

    with open(specfile, 'r', encoding='utf-8', newline='\n') as specf:
        for line in specf:
            line_number = line_number + 1
            l = line.strip()
            if l.startswith("`" * 32 + " example"):
                state = 1
                extensions = l[32 + len(" example"):].split()
            elif l == "`" * 32:
                state = 0
                example_number = example_number + 1
                end_line = line_number
                if 'disabled' not in extensions:
                    tests.append({
                        "markdown":''.join(markdown_lines).replace('→',"\t"),
                        "html":''.join(html_lines).replace('→',"\t"),
                        "example": example_number,
                        "start_line": start_line,
                        "end_line": end_line,
                        "section": headertext,
                        "extensions": extensions})
                start_line = 0
                markdown_lines = []
                html_lines = []
            elif l == ".":
                state = 2
            elif state == 1:
                if start_line == 0:
                    start_line = line_number - 1
                markdown_lines.append(line)
            elif state == 2:
                html_lines.append(line)
            elif state == 0 and re.match(header_re, line):
                headertext = header_re.sub('', line).strip()
    return tests

=end
# rubocop:enable Style/BlockComments
# rubocop:enable Style/AsciiComments
