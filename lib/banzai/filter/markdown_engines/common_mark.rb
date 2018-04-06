# `CommonMark` markdown engine for GitLab's Banzai markdown filter.
# This module is used in Banzai::Filter::MarkdownFilter.
# Used gem is `commonmarker` which is a ruby wrapper for libcmark (CommonMark parser)
# including GitHub's GFM extensions.
# Homepage: https://github.com/gjtorikian/commonmarker

module Banzai
  module Filter
    module MarkdownEngines
      class CommonMark
        EXTENSIONS = [
          :autolink,      # provides support for automatically converting URLs to anchor tags.
          :strikethrough, # provides support for strikethroughs.
          :table,         # provides support for tables.
          :tagfilter      # strips out several "unsafe" HTML tags from being used: https://github.github.com/gfm/#disallowed-raw-html-extension-
        ].freeze

        PARSE_OPTIONS = [
          :FOOTNOTES,                  # parse footnotes.
          :STRIKETHROUGH_DOUBLE_TILDE, # parse strikethroughs by double tildes (as redcarpet does).
          :VALIDATE_UTF8	             # replace illegal sequences with the replacement character U+FFFD.
        ].freeze

        # The `:GITHUB_PRE_LANG` option is not used intentionally because
        # it renders a fence block with language as `<pre lang="LANG"><code>some code\n</code></pre>`
        # while GitLab's syntax is `<pre><code lang="LANG">some code\n</code></pre>`.
        # If in the future the syntax is about to be made GitHub-compatible, please, add `:GITHUB_PRE_LANG` render option below
        # and remove `code_block` method from `lib/banzai/renderer/common_mark/html.rb`.
        RENDER_OPTIONS = [
          :DEFAULT # default rendering system. Nothing special.
        ].freeze

        def initialize
          @renderer = Banzai::Renderer::CommonMark::HTML.new(options: RENDER_OPTIONS)
        end

        def render(text)
          doc = CommonMarker.render_doc(text, PARSE_OPTIONS, EXTENSIONS)

          @renderer.render(doc)
        end
      end
    end
  end
end
