module Gitlab
  module Diff
    class InlineDiffMarker < Gitlab::StringRangeMarker
      def mark(line_inline_diffs, mode: nil)
        mark = super(line_inline_diffs) do |text, left:, right:|
          %{<span class="#{html_class_names(left, right, mode)}">#{text}</span>}
        end
        mark.html_safe
      end

      private

      def html_class_names(left, right, mode)
        class_names = ["idiff"]
        class_names << "left"  if left
        class_names << "right" if right
        class_names << mode if mode
        class_names.join(" ")
      end
    end
  end
end
