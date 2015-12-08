require 'gitlab/markdown'

module Gitlab
  module Markdown
    class FullPipeline < CombinedPipeline.new(PlainMarkdownPipeline, GfmPipeline)

    end
  end
end
