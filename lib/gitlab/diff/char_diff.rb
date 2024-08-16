# frozen_string_literal: true

module Gitlab
  module Diff
    class CharDiff
      include Gitlab::Utils::StrongMemoize

      def initialize(old_string, new_string)
        @old_string = old_string.to_s
        @new_string = new_string.to_s
        @changes = []
      end

      def generate_diff
        @changes = diff_match_patch.diff_main(@old_string, @new_string)
        diff_match_patch.diff_cleanupSemantic(@changes)

        @changes
      end

      def changed_ranges(offset: 0)
        old_diffs = []
        new_diffs = []
        new_pointer = old_pointer = offset

        generate_diff.each do |(action, content)|
          content_size = content.size

          if action == :equal
            new_pointer += content_size
            old_pointer += content_size
          end

          if action == :delete
            old_diffs << MarkerRange.new(old_pointer, old_pointer + content_size - 1, mode: MarkerRange::DELETION)
            old_pointer += content_size
          end

          if action == :insert
            new_diffs << MarkerRange.new(new_pointer, new_pointer + content_size - 1, mode: MarkerRange::ADDITION)
            new_pointer += content_size
          end
        end

        [old_diffs, new_diffs]
      end

      def to_html
        @changes.map do |op, text|
          text = ERB::Util.html_escape(text)
          text.gsub!("\n", "↵\n") if op == :insert || op == :delete

          %(<span class="#{html_class_names(op)}">#{text}</span>)
        end.join.html_safe
      end

      private

      def diff_match_patch
        strong_memoize(:diff_match_patch) { DiffMatchPatch.new }
      end

      def html_class_names(operation)
        class_names = ['idiff']

        case operation
        when :insert
          class_names << 'addition'
        when :delete
          class_names << 'deletion'
        end

        class_names.join(' ')
      end
    end
  end
end
