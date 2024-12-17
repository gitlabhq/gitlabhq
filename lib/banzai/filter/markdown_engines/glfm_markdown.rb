# frozen_string_literal: true

require 'glfm_markdown'

# Use the glfm_markdown gem (https://gitlab.com/gitlab-org/ruby/gems/gitlab-glfm-markdown)
# to interface with the Rust based `comrak` parser
# https://github.com/kivikakk/comrak
module Banzai
  module Filter
    module MarkdownEngines
      class GlfmMarkdown < Base
        OPTIONS = {
          autolink: true,
          description_lists: true,
          escaped_char_spans: true,
          footnotes: true,
          full_info_string: true,
          github_pre_lang: true,
          hardbreaks: false,
          header_ids: Banzai::Renderer::USER_CONTENT_ID_PREFIX,
          math_code: true,
          math_dollars: true,
          multiline_block_quotes: true,
          relaxed_autolinks: true,
          sourcepos: true,
          experimental_inline_sourcepos: true,
          smart: false,
          strikethrough: true,
          table: true,
          tagfilter: false,
          tasklist: false, # still handled by a banzai filter/gem,
          wikilinks_title_before_pipe: true,
          unsafe: true
        }.freeze

        def render(text)
          ::GLFMMarkdown.to_html(text, options: render_options)
        end

        private

        def render_options
          return OPTIONS unless sourcepos_disabled? || headers_disabled? || autolink_disabled? || raw_html_disabled?

          OPTIONS.merge(
            sourcepos: !sourcepos_disabled?,
            experimental_inline_sourcepos: sourcepos_disabled? ? false : OPTIONS[:experimental_inline_sourcepos],
            header_ids: headers_disabled? ? nil : OPTIONS[:header_ids],
            autolink: !autolink_disabled?,
            relaxed_autolinks: !autolink_disabled?,
            unsafe: !raw_html_disabled?
          )
        end

        def headers_disabled?
          context[:no_header_anchors]
        end

        def autolink_disabled?
          context[:autolink] == false
        end

        def raw_html_disabled?
          context[:disable_raw_html]
        end
      end
    end
  end
end

Banzai::Filter::MarkdownEngines::GlfmMarkdown.prepend_mod
