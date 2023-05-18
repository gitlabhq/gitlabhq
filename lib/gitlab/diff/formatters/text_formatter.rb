# frozen_string_literal: true

module Gitlab
  module Diff
    module Formatters
      class TextFormatter < BaseFormatter
        attr_reader :old_line
        attr_reader :new_line
        attr_reader :line_range

        def initialize(attrs)
          @old_line = attrs[:old_line]
          @new_line = attrs[:new_line]
          @line_range = attrs[:line_range]
          @ignore_whitespace_change = !!attrs[:ignore_whitespace_change]

          super(attrs)
        end

        def key
          @key ||= super.push(old_line, new_line)
        end

        def complete?
          old_line.present? || new_line.present?
        end

        def to_h
          super.merge(old_line: old_line, new_line: new_line, line_range: line_range,
            ignore_whitespace_change: ignore_whitespace_change)
        end

        def line_age
          if old_line && new_line
            nil
          elsif new_line
            'new'
          else
            'old'
          end
        end

        def position_type
          "text"
        end

        def ==(other)
          other.is_a?(self.class) &&
            new_line == other.new_line &&
            old_line == other.old_line &&
            line_range == other.line_range
        end
      end
    end
  end
end
