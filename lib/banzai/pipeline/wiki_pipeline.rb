require 'banzai'

module Banzai
  module Pipeline
    class WikiPipeline < CombinedPipeline.new(PlainMarkdownPipeline, GollumTagsPipeline, GfmPipeline)

    end
  end
end
