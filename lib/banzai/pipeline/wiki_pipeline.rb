require 'banzai'

module Banzai
  module Pipeline
    class WikiPipeline < FullPipeline
      def self.filters
        @filters ||= begin
                       filters = super
                       toc = filters.index(Filter::TableOfContentsFilter)
                       filters.insert(toc + 1, Filter::GollumTagsFilter)
                     end
      end
    end
  end
end
