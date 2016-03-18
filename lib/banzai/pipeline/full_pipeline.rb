module Banzai
  module Pipeline
    class FullPipeline < CombinedPipeline.new(PlainMarkdownPipeline, GfmPipeline)

    end
  end
end
