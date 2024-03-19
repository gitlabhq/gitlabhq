# frozen_string_literal: true

# `CommonMark` markdown engine for GitLab's Banzai markdown filter.
# This module is used in Banzai::Filter::MarkdownFilter.
# Used gem is `commonmarker` which is a ruby wrapper for cmark-gfm (CommonMark parser)
# including GitHub's GFM extensions.
# We now utilize the renderer built in `C`, rather than the ruby based renderer.
# Homepage: https://github.com/gjtorikian/commonmarker
#
# Although this engine is currently not actively used, let's keep it here
# for performance testing and as a backup.
module Banzai
  module Filter
    module MarkdownEngines
      class Cmark < Base
        EXTENSIONS = [
          :autolink,      # provides support for automatically converting URLs to anchor tags.
          :strikethrough, # provides support for strikethroughs.
          :table          # provides support for tables.
        ].freeze

        PARSE_OPTIONS = [
          :FOOTNOTES,                  # parse footnotes.
          :STRIKETHROUGH_DOUBLE_TILDE, # parse strikethroughs by double tildes (as redcarpet does).
          :VALIDATE_UTF8               # replace illegal sequences with the replacement character U+FFFD.
        ].freeze

        RENDER_OPTIONS = [
          :GITHUB_PRE_LANG,  # use GitHub-style <pre lang> for fenced code blocks.
          :FOOTNOTES,        # render footnotes.
          :FULL_INFO_STRING, # include full info strings of code blocks in separate attribute.
          :UNSAFE            # allow raw/custom HTML and unsafe links.
        ].freeze

        RENDER_OPTIONS_SOURCEPOS = RENDER_OPTIONS + [:SOURCEPOS].freeze

        def render(text)
          CommonMarker.render_html(text, render_options, EXTENSIONS)
        end

        private

        def render_options
          sourcepos_disabled? ? RENDER_OPTIONS : RENDER_OPTIONS_SOURCEPOS
        end
      end
    end
  end
end

Banzai::Filter::MarkdownEngines::Cmark.prepend_mod
