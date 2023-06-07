# frozen_string_literal: true

module Gitlab
  module Diff
    module Formatters
      class FileFormatter < BaseFormatter
        def initialize(attrs)
          @ignore_whitespace_change = false

          super(attrs)
        end

        def key
          @key ||= super.push(new_path, old_path)
        end

        def position_type
          "file"
        end

        def complete?
          [new_path, old_path].all?(&:present?)
        end

        def ==(other)
          other.is_a?(self.class) &&
            old_path == other.old_path &&
            new_path == other.new_path
        end
      end
    end
  end
end
