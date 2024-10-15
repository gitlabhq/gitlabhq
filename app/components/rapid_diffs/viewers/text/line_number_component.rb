# frozen_string_literal: true

module RapidDiffs
  module Viewers
    module Text
      class LineNumberComponent < ViewComponent::Base
        def initialize(diff_file:, line:, position:)
          @diff_file = diff_file
          @line = line
          @position = position
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

        def visible?
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
