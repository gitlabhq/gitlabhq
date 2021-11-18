# frozen_string_literal: true

# Remove this entire file when removing `use_cmark_renderer` feature flag and switching to the CMARK html renderer.
# https://gitlab.com/gitlab-org/gitlab/-/issues/345744
module Banzai
  module Renderer
    module CommonMark
      class HTML < CommonMarker::HtmlRenderer
        def code_block(node)
          block do
            out("<pre#{sourcepos(node)}><code")
            out(' lang="', node.fence_info, '"') if node.fence_info.present?
            out('>')
            out(escape_html(node.string_content))
            out('</code></pre>')
          end
        end
      end
    end
  end
end
