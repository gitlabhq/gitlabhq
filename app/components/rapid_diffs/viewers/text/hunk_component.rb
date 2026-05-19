# frozen_string_literal: true

module RapidDiffs
  module Viewers
    module Text
      class HunkComponent < ViewComponent::Base
        ICON_NAMES = {
          up: 'expand-up',
          down: 'expand-down',
          both: 'expand'
        }.freeze

        with_collection_parameter :diff_hunk

        def initialize(diff_hunk:, file_hash:)
          @diff_hunk = diff_hunk
          @file_hash = file_hash
        end

        private

        def line_number(line, position)
          position == :old ? line.old_pos : line.new_pos
        end

        def line_change_type(line)
          return unless line
          return 'meta' if line.meta?
          return 'added' if line.added?

          'removed' if line.removed?
        end

        def line_number_label(line, position)
          number = line_number(line, position)
          return s_('RapidDiffs|Removed line %d') % number if line.removed?
          return s_('RapidDiffs|Added line %d') % number if line.added?

          s_('RapidDiffs|Line %d') % number
        end

        def line_number_visible?(line, position)
          return false unless line && !line.meta?

          case position
          when :old then !line.added?
          when :new then !line.removed?
          else false
          end
        end

        def expand_icon_name(direction)
          ICON_NAMES[direction]
        end

        def expand_label(direction)
          case direction
          when :up   then s_('RapidDiffs|Show lines before')
          when :down then s_('RapidDiffs|Show lines after')
          when :both then s_('RapidDiffs|Show hidden lines')
          end
        end

        def expand_buttons
          buttons = @diff_hunk.header.expand_directions.map do |direction|
            tag.button(
              type: 'button',
              class: 'rd-expand-lines-button has-tooltip',
              title: expand_label(direction),
              data: { click: 'expandLines', expand_direction: direction },
              aria: { label: expand_label(direction) }
            ) do
              tag.span(helpers.sprite_icon(expand_icon_name(direction)), data: { visible_when: 'idle' }) +
                tag.span(helpers.gl_loading_icon(size: 'sm', inline: true), data: { visible_when: 'loading' })
            end
          end
          safe_join(buttons)
        end

        def line_number_cell(line, line_id, change, position)
          if line_number_visible?(line, position)
            tag.td(class: 'rd-line-number', data: { change: change, position: position }) do
              number = line_number(line, position)
              if number > 0
                link_to('', "##{line_id}", class: 'rd-line-link',
                  data: { line_number: number },
                  aria: { label: line_number_label(line, position) })
              else
                tag.span
              end
            end
          else
            tag.td(class: 'rd-line-number rd-line-number-empty', data: { change: change, position: position })
          end
        end

        def line_content_cell(line, change, position)
          css = line ? 'rd-line-content' : 'rd-line-content rd-line-number-empty'
          content = line ? tag.pre(line.text_content, class: 'rd-line-text') : nil
          tag.td(content, class: css, data: { change: change, position: position })
        end
      end
    end
  end
end
