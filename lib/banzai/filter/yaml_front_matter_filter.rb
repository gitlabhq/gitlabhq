require 'html/pipeline/filter'
require 'yaml'

module Banzai
  module Filter
    class YamlFrontMatterFilter < HTML::Pipeline::Filter
      DELIM = '---'.freeze

      # Hat-tip to Middleman: https://git.io/v2e0z
      PATTERN = %r{
        \A(?:[^\r\n]*coding:[^\r\n]*\r?\n)?
        (?<start>#{DELIM})[ ]*\r?\n
        (?<frontmatter>.*?)[ ]*\r?\n?
        ^(?<stop>#{DELIM})[ ]*\r?\n?
        \r?\n?
        (?<content>.*)
      }mx.freeze

      def call
        match = PATTERN.match(html)

        return html unless match

        "```yaml\n#{match['frontmatter']}\n```\n\n#{match['content']}"
      end
    end
  end
end
