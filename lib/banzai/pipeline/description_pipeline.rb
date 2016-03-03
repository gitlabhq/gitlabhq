module Banzai
  module Pipeline
    class DescriptionPipeline < FullPipeline
      def self.transform_context(context)
        super(context).merge(
          # SanitizationFilter
          whitelist: whitelist
        )
      end

      private

      def self.whitelist
        # Descriptions are more heavily sanitized, allowing only a few elements.
        # See http://git.io/vkuAN
        whitelist = Banzai::Filter::SanitizationFilter::LIMITED
        whitelist[:elements] -= %w(pre code img ol ul li)

        whitelist
      end
    end
  end
end
