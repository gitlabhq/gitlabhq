# frozen_string_literal: true

module Gitlab
  module Asciidoc
    module SyntaxHighlighter
      class HtmlPipelineAdapter < Asciidoctor::SyntaxHighlighter::Base
        register_for 'gitlab-html-pipeline'

        def format(node, lang, opts)
          %(<pre #{lang ? %(lang="#{lang}") : ''}><code>#{node.content}</code></pre>)
        end
      end
    end
  end
end
