# frozen_string_literal: true

module Banzai
  module Pipeline
    class DescriptionPipeline < FullPipeline
      WHITELIST = Banzai::Filter::SanitizationFilter::LIMITED.deep_dup.merge(
        elements: Banzai::Filter::SanitizationFilter::LIMITED[:elements] - %w(pre code img ol ul li)
      )

      def self.transform_context(context)
        super(context).merge(
          # SanitizationFilter
          whitelist: WHITELIST
        )
      end
    end
  end
end
