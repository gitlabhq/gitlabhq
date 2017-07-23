module Banzai
  module Renderer
    class HTML < Redcarpet::Render::HTML
      def block_code(code, lang)
        lang_attr = lang ? %Q{ lang="#{lang}"} : ''

        "\n<pre>" \
          "<code#{lang_attr}>#{html_escape(code)}</code>" \
        "</pre>"
      end
    end
  end
end
