# frozen_string_literal: true

module RapidDiffs
  module Viewers
    module Text
      class LineNumberComponent < ViewComponent::Base
        def initialize(line:, line_id:, position:, border: nil)
          @line = line
          @line_id = line_id
          @position = position
          @border = border
        end

        def line_number
          @position == :old ? @line.old_pos : @line.new_pos
        end

        def change_type
          return unless @line
          return 'meta' if @line.meta?
          return 'added' if @line.added?

          'removed' if @line.removed?
        end

        def border_class
          case @border
          when :right then 'rd-line-number-border-right'
          when :both  then 'rd-line-number-border-both'
          end
        end

        def label
          return s_('RapidDiffs|Removed line %d') % line_number if @line.removed?
          return s_('RapidDiffs|Added line %d') % line_number if @line.added?

          s_('RapidDiffs|Line %d') % line_number
        end

        def visible?
          return false unless @line && !@line.meta?

          case @position
          when :old then !@line.added?
          when :new then !@line.removed?
          else false
          end
        end
      end
    end
  end
end
