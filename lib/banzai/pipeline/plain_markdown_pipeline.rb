# frozen_string_literal: true

module Banzai
  module Pipeline
    class PlainMarkdownPipeline < BasePipeline
      # DollarMathPreFilter and DollarMathPostFilter need to be included here,
      # rather than in another pipeline.  However, since dollar math would most
      # likely be supported as an extension in any other markdown parser we used,
      # it is not out of place.  We are considering this a part of the actual
      # markdown processing
      def self.filters
        FilterArray[
          Filter::MarkdownPreEscapeFilter,
          Filter::DollarMathPreFilter,
          Filter::BlockquoteFenceFilter,
          Filter::MarkdownFilter,
          Filter::DollarMathPostFilter,
          Filter::MarkdownPostEscapeFilter
        ]
      end
    end
  end
end
