module Banzai
  module Pipeline
    class WikiPipeline < FullPipeline
      def self.filters
        @filters ||= begin
          super.insert_after(Filter::TableOfContentsFilter, Filter::GollumTagsFilter)
               .insert_before(Filter::TaskListFilter, Filter::WikiLinkFilter)
               .insert_before(Filter::VideoLinkFilter, Filter::SpacedLinkFilter)
        end
      end
    end
  end
end
