# frozen_string_literal: true

module Gitlab
  module Database
    module Diagnostics
      module Console
        # Writes through an injected IO so Rails/Output stays quiet and specs can
        # assert against a StringIO.
        class Printer
          INDENT = '   '
          COLUMN_GAP = '  '
          WRAP_WIDTH = 96

          SEVERITY_COLORS = {
            Findings::ERROR => :red,
            Findings::WARNING => :yellow
          }.freeze

          def initialize(output: $stdout)
            @output = output
          end

          # rstrip so a padded tag or absent value leaves no trailing whitespace.
          def line(text = '')
            @output.puts(text.to_s.rstrip)
          end

          def blank_line
            line
          end

          def section(title)
            blank_line
            line("== #{title} ==")
            blank_line
          end

          def status(label, summary, severity)
            line("#{label} ... #{colorize(summary, severity)}")
          end

          def subheading(text)
            line("#{INDENT}#{text}")
          end

          def key_value(label, value, label_width: 0)
            line("#{INDENT}#{"#{label}:".ljust(label_width)} #{value}")
          end

          # Tag padded to the widest severity so message bodies align.
          def finding(severity, message)
            tag = "[#{severity}]".ljust(tag_width)
            hanging = ' ' * (INDENT.length + tag.length + 1)

            wrap(message, WRAP_WIDTH - hanging.length).each_with_index do |chunk, index|
              line(index == 0 ? "#{INDENT}#{colorize(tag, severity)} #{chunk}" : "#{hanging}#{chunk}")
            end
          end

          def detail(text)
            wrap(text, WRAP_WIDTH - INDENT.length).each { |chunk| line("#{INDENT}#{chunk}") }
          end

          def table(headers, rows)
            AsciiTable.new(rows, headers: headers, gap: COLUMN_GAP).lines.each do |table_line|
              line(INDENT + table_line)
            end
          end

          # $stdout is block-buffered when redirected; a slow check would look hung.
          def flush
            @output.flush
          end

          private

          def tag_width
            @tag_width ||= Findings::SEVERITY_ORDER.keys.map { |severity| severity.length + 2 }.max
          end

          # Green means nothing to report. Unknown severity falls back to yellow, as in the Vue card.
          def colorize(text, severity)
            return Rainbow(text).green if severity.nil?

            Rainbow(text).color(SEVERITY_COLORS.fetch(severity, :yellow))
          end

          def wrap(text, width)
            lines = text.to_s.split(/\s+/).each_with_object([]) do |word, wrapped|
              if wrapped.empty? || (wrapped.last.length + 1 + word.length) > width
                wrapped << word.dup
              else
                wrapped.last << ' ' << word
              end
            end

            lines.presence || ['']
          end
        end
      end
    end
  end
end
