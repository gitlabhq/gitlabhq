require 'banzai'

module Banzai
  module Pipeline
    class WikiPipeline < FullPipeline
      def self.filters
        super.insert(1, Filter::GollumTagsFilter)
      end
    end
  end
end
