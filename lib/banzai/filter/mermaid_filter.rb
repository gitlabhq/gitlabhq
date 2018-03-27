module Banzai
  module Filter
    class MermaidFilter < HTML::Pipeline::Filter
      def call
        doc.css('pre[lang="mermaid"] > code').add_class('js-render-mermaid')

        doc
      end
    end
  end
end
