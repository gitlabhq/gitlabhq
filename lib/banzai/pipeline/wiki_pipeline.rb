module Banzai
  module Pipeline
    class WikiPipeline < FullPipeline
      def self.filters
        @filters ||= begin
          super.insert_after(Filter::TableOfContentsFilter, Filter::GollumTagsFilter)
               .insert_after(Filter::TableOfContentsFilter, Filter::WikiLinkFilter)
        end
      end
    end
  end
end
