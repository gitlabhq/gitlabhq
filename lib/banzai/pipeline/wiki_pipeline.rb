require 'banzai'

module Banzai
  module Pipeline
    class WikiPipeline < FullPipeline
      def self.filters
        @filters ||= super.insert_after(Filter::TableOfContentsFilter,
                                        Filter::GollumTagsFilter)
      end
    end
  end
end
