# frozen_string_literal: true

module RapidDiffs
  module Viewers
    module Text
      class TextViewComponent < ViewerComponent
        def virtual_rendering_params
          @virtual_rendering_params ||= { total_rows: total_rows }
        end
      end
    end
  end
end
