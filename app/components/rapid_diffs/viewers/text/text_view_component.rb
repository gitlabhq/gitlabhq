# frozen_string_literal: true

module RapidDiffs
  module Viewers
    module Text
      class TextViewComponent < ViewerComponent
        def lines
          raise NotImplementedError
        end

        def diff_line(line)
          raise NotImplementedError
        end

        def hunk_view_component
          raise NotImplementedError
        end

        def column_titles
          raise NotImplementedError
        end

        def hunk_view(diff_hunk)
          hunk_view_component.new(
            diff_hunk: diff_hunk,
            diff_file: @diff_file
          )
        end

        def diff_hunks
          return [] if lines.empty?

          hunks = []
          current_hunk = nil

          lines.each do |line|
            current_line = diff_line(line)
            is_match = current_line.type == 'match'

            if is_match || current_hunk.nil?
              current_hunk = create_hunk(hunks.last, current_hunk, current_line, is_match, line)
              hunks << current_hunk
            else
              current_hunk[:lines] << line
            end
          end

          hunks
        end

        private

        def create_hunk(prev, current_hunk, current_line, is_match, line)
          new_hunk = {
            header: is_match ? current_line : nil,
            lines: is_match ? [] : [line],
            prev: prev
          }

          current_hunk[:next] = new_hunk if current_hunk
          new_hunk
        end
      end
    end
  end
end
