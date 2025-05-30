# frozen_string_literal: true

module Banzai
  module Pipeline
    class NotePipeline < FullPipeline
      def self.transform_context(context)
        super(context).merge(
          no_header_anchors: true
        )
      end
    end
  end
end
