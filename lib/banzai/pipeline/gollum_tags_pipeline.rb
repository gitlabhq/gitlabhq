require 'banzai'

module Banzai
  module Pipeline
    class GollumTagsPipeline < BasePipeline
      def self.filters
        [
          Filter::GollumTagsFilter
        ]
      end
    end
  end
end
