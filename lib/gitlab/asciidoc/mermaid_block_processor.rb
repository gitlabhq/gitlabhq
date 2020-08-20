# frozen_string_literal: true

require 'asciidoctor'

module Gitlab
  module Asciidoc
    # Mermaid BlockProcessor
    class MermaidBlockProcessor < ::Asciidoctor::Extensions::BlockProcessor
      use_dsl

      named :mermaid
      on_context :literal, :listing
      parse_content_as :simple

      def process(parent, reader, attrs)
        create_mermaid_source_block(parent, reader.read, attrs)
      end

      private

      def create_mermaid_source_block(parent, content, attrs)
        # If "subs" attribute is specified, substitute accordingly.
        # Be careful not to specify "specialcharacters" or your diagram code won't be valid anymore!
        subs = attrs['subs']
        content = parent.apply_subs(content, parent.resolve_subs(subs)) if subs
        html = %(<div><pre data-mermaid-style="display">#{CGI.escape_html(content)}</pre></div>)
        ::Asciidoctor::Block.new(parent, :pass, {
          content_model: :raw,
          source: html,
          subs: :default
        }.merge(attrs))
      end
    end
  end
end
