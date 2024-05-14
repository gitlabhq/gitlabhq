# frozen_string_literal: true

require 'asciidoctor'

module Gitlab
  module Asciidoc
    class Html5Converter < (Asciidoctor::Converter.for 'html5')
      register_for 'gitlab_html5'

      def convert_stem(node)
        return super unless node.style.to_sym == :latexmath

        %(<pre#{id_attribute(node)} data-math-style="display"><code>#{node.content}</code></pre>)
      end

      def convert_inline_quoted(node)
        return super unless node.type.to_sym == :latexmath

        %(<code#{id_attribute(node)} data-math-style="inline">#{node.text}</code>)
      end

      def convert_inline_anchor(node)
        if node.id && !node.id.start_with?(Banzai::Renderer::USER_CONTENT_ID_PREFIX)
          node.id = "#{Banzai::Renderer::USER_CONTENT_ID_PREFIX}#{node.id}"
        end

        super(node)
      end

      private

      def id_attribute(node)
        node.id ? %( id="#{node.id}") : nil
      end
    end
  end
end
