module Banzai
  module Filter
    class MermaidFilter < HTML::Pipeline::Filter
      def call
        doc.css('pre[lang="mermaid"]').add_class('mermaid')
        doc.css('pre[lang="mermaid"]').add_class('js-render-mermaid')

        # The `<code></code>` blocks are added in the lib/banzai/filter/syntax_highlight_filter.rb
        # We want to keep context and consistency, so we the blocks are added for all filters.
        # Details: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/15107/diffs?diff_id=7962900#note_45495859
        doc.css('pre[lang="mermaid"]').each do |pre|
          document = pre.at('code')
          document.replace(document.content)
        end

        doc
      end
    end
  end
end
