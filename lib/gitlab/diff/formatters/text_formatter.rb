module Gitlab
  module Diff
    module Formatters
      class TextFormatter < BaseFormatter
        attr_reader :old_line
        attr_reader :new_line

        def initialize(attrs)
          @old_line = attrs[:old_line]
          @new_line = attrs[:new_line]

          super(attrs)
        end

        def key
          @key ||= super.push(old_line, new_line)
        end

        def complete?
          old_line || new_line
        end

        def to_h
          super.merge(old_line: old_line, new_line: new_line)
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
            old_line == other.old_line
        end
      end
    end
  end
end
