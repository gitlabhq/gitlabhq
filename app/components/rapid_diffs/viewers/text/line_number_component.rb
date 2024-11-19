# frozen_string_literal: true

module RapidDiffs
  module Viewers
    module Text
      class LineNumberComponent < ViewComponent::Base
        def initialize(diff_file:, line:, position:, border: nil)
          @diff_file = diff_file
          @line = line
          @position = position
          @border = border
        end

        def id
          @line.id(@diff_file.file_hash, @position)
        end

        def line_number
          @position == :old ? @line.old_pos : @line.new_pos
        end

        def legacy_id
          @diff_file.line_code(@line)
        end

        def change_type
          return unless @line

          return 'added' if @line.added?

          'removed' if @line.removed?
        end

        def border_class
          case @border
          when :right then 'rd-line-number-border-right'
          when :both  then 'rd-line-number-border-both'
          end
        end

        def visible?
          return false unless @line

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
