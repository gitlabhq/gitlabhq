# frozen_string_literal: true

module RapidDiffs
  module Viewers
    module Text
      class TextViewComponent < ViewerComponent
        def virtual_rendering_params
          @virtual_rendering_params ||= { total_rows: total_rows }
        end

        private

        def table_caption
          added = helpers.safe_format(
            ns_('RapidDiffs|%{count} added line', 'RapidDiffs|%{count} added lines', @diff_file.added_lines),
            count: @diff_file.added_lines
          )
          removed = helpers.safe_format(
            ns_('RapidDiffs|%{count} removed line', 'RapidDiffs|%{count} removed lines', @diff_file.removed_lines),
            count: @diff_file.removed_lines
          )
          helpers.safe_format(
            s_('RapidDiffs|Changes for %{path}: %{added}, %{removed}.'),
            path: @diff_file.file_path, added: added, removed: removed
          )
        end
      end
    end
  end
end
