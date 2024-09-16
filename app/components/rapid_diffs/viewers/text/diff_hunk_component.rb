# frozen_string_literal: true

module RapidDiffs
  module Viewers
    module Text
      class DiffHunkComponent < ViewComponent::Base
        include ::Gitlab::Utils::StrongMemoize

        MAX_EXPANDABLE_LINES = 20

        def initialize(diff_hunk:, diff_file:)
          @diff_hunk = diff_hunk
          @diff_file = diff_file
        end

        def line_content(line)
          if line.blank?
            ""
          else
            # `sub` and substring-ing would destroy HTML-safeness of `line`
            line[1, line.length]
          end
        end

        def line_text(line)
          return unless line

          line.rich_text ? line_content(line.rich_text) : line.text
        end

        def line_link(line, position)
          return [] unless line && !line.meta?

          line_number = position == :new ? line.new_pos : line.old_pos
          id = @diff_file.line_side_code(line, position)
          link = link_to line_number, "##{id}", { data: { line_number: line_number } }
          [link, id]
        end

        def legacy_id(line)
          return unless line

          @diff_file.line_code(line)
        end

        def header_text
          @diff_hunk[:header].text
        end

        def expand_buttons
          return render ExpandLinesComponent.new(direction: :both) if show_expand_both?

          buttons = ''
          buttons += render ExpandLinesComponent.new(direction: :down) if show_expand_down?
          buttons += render ExpandLinesComponent.new(direction: :up) if show_expand_up?
          buttons
        end
        strong_memoize_attr :expand_buttons

        private

        def line_count_between
          raise NotImplementedError
        end

        def show_expand_both?
          line_count_between != 0 && line_count_between < MAX_EXPANDABLE_LINES
        end

        def show_expand_down?
          @diff_hunk[:lines].empty? || @diff_hunk[:prev]
        end

        def show_expand_up?
          !@diff_hunk[:header]&.index.nil?
        end
      end
    end
  end
end
