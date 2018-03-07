module Banzai
  module Renderer
    module CommonMark
      class HTML < CommonMarker::HtmlRenderer
        def code_block(node)
          block do
            code      = node.string_content
            lang      = node.fence_info
            lang_attr = lang.present? ? %Q{ lang="#{lang}"} : ''
            result    =
              "<pre>" \
                "<code#{lang_attr}>#{html_escape(code)}</code>" \
              "</pre>"

            out(result)
          end
        end
      end
    end
  end
end
