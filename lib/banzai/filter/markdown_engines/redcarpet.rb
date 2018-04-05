# `Redcarpet` markdown engine for GitLab's Banzai markdown filter.
# This module is used in Banzai::Filter::MarkdownFilter.
# Used gem is `redcarpet` which is a ruby library for markdown processing.
# Homepage: https://github.com/vmg/redcarpet

module Banzai
  module Filter
    module MarkdownEngines
      class Redcarpet
        OPTIONS = {
          fenced_code_blocks:  true,
          footnotes:           true,
          lax_spacing:         true,
          no_intra_emphasis:   true,
          space_after_headers: true,
          strikethrough:       true,
          superscript:         true,
          tables:              true
        }.freeze

        def initialize
          html_renderer = Banzai::Renderer::Redcarpet::HTML.new
          @renderer = ::Redcarpet::Markdown.new(html_renderer, OPTIONS)
        end

        def render(text)
          @renderer.render(text)
        end
      end
    end
  end
end
