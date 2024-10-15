# frozen_string_literal: true

module RapidDiffs
  module Viewers
    module Text
      class ParallelViewComponent < ViewerComponent
        def self.viewer_name
          'text_parallel'
        end

        def column_titles
          [
            s_('RapidDiffs|Original line number'),
            s_('RapidDiffs|Original line'),
            s_('RapidDiffs|Diff line number'),
            s_('RapidDiffs|Diff line')
          ]
        end
      end
    end
  end
end
