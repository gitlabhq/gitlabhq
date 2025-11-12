# frozen_string_literal: true

require 'glfm_markdown'

# Use the glfm_markdown gem (https://gitlab.com/gitlab-org/ruby/gems/gitlab-glfm-markdown)
# to interface with the Rust based `comrak` parser
# https://github.com/kivikakk/comrak
module Banzai
  module Filter
    module MarkdownEngines
      class GlfmMarkdown < Base
        # Table of characters that need this special handling. It consists of
        # the GitLab special reference characters.
        REFERENCE_CHARS = %w[$ % # & @ ! ~ ^ :].freeze

        OPTIONS = {
          alerts: true,
          autolink: true,
          cjk_friendly_emphasis: true,
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
          only_escape_chars: REFERENCE_CHARS,
          placeholder_detection: true,
          relaxed_autolinks: true,
          sourcepos: true,
          smart: false,
          strikethrough: true,
          table: true,
          tagfilter: false,
          tasklist: false, # still handled by a banzai filter/gem,
          wikilinks_title_before_pipe: true,
          unsafe: true
        }.freeze

        # Supports the bare minimum markdown. Usually used for single line
        # titles.
        MINIMUM_MARKDOWN = {
          autolink: true,
          hardbreaks: false,
          strikethrough: true,
          unsafe: false,
          relaxed_autolinks: true
        }.freeze

        def render(text)
          ::GLFMMarkdown.to_html(text, options: render_options)
        end

        private

        def render_options
          return MINIMUM_MARKDOWN if minimum_markdown_enabled?

          unless sourcepos_disabled? || headers_disabled? || autolink_disabled? || raw_html_disabled? ||
              placeholders_disabled?
            return OPTIONS
          end

          OPTIONS.merge(
            sourcepos: !sourcepos_disabled?,
            header_ids: headers_disabled? ? nil : OPTIONS[:header_ids],
            autolink: !autolink_disabled?,
            relaxed_autolinks: !autolink_disabled?,
            placeholder_detection: !placeholders_disabled?,
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

        def minimum_markdown_enabled?
          context[:minimum_markdown]
        end

        def placeholders_disabled?
          return true unless resolve_project&.markdown_placeholders_feature_flag_enabled? ||
            context[:group]&.markdown_placeholders_feature_flag_enabled?

          context[:disable_placeholders] || context[:broadcast_message_placeholders]
        end

        def resolve_project
          context[:project].respond_to?(:project) ? context[:project].project : context[:project]
        end
      end
    end
  end
end

Banzai::Filter::MarkdownEngines::GlfmMarkdown.prepend_mod
