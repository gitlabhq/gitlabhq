# frozen_string_literal: true

module Banzai
  module Pipeline
    class IssuableTitlePipeline < SingleLinePipeline
      def self.filters
        @filters ||= super.insert_before(Filter::EmojiFilter, Filter::CodeSpanFilter)
      end
    end
  end
end
