# frozen_string_literal: true

module RapidDiffs
  module Viewers
    module Text
      class InlineViewComponent < ViewerComponent
        def self.viewer_name
          'text_inline'
        end

        def column_titles
          [
            s_('RapidDiffs|Original line number'),
            s_('RapidDiffs|Diff line number'),
            s_('RapidDiffs|Diff line')
          ]
        end
      end
    end
  end
end
