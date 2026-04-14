# frozen_string_literal: true

# Override the html-pipeline gem's HTML fragment parsing to use Nokogiri's HTML5
# (Gumbo-based) parser instead of the HTML4 (libxml2-based) parser.
#
# The HTML4 parser applies tree construction rules that incorrectly restructure
# the DOM when inline raw HTML block-level elements (e.g. <div>, <section>) appear
# inside list items. For example, `<li>text <div></li>` causes the HTML4 parser to
# leave the <div> open (since </li> cannot close a block element in HTML4), which
# swallows all subsequent content (i.e. the rest of the actual page on GitLab!)
# into the <div>.
#
# The HTML5 parser correctly handles this per the WHATWG specification by closing
# block elements when implied end tags are generated.
#
# See https://gitlab.com/gitlab-org/gitlab/-/work_items/594217.

module HTML
  class Pipeline
    module HTML5Patch
      # The libxml2-based parser simply stops nesting elements after a certain depth.
      # Gumbo does not, and will nest them arbitrarily deep unless we specify a maximum,
      # at which point it will raise an exception.
      # We choose a maximum depth because Sanitize will exhaust the stack recursing on the
      # DOM at high nesting depth.
      # The selected number is higher than any reasonable document will need.
      HTML5_MAX_TREE_DEPTH = 4096

      TREE_DEPTH_LIMIT_ERROR = 'Document tree depth limit exceeded'

      NESTING_TOO_DEEP_MESSAGE =
        <<~HTML
          <p>Rendering aborted because the document's nesting was too deep. Please reduce the
          level of nesting in your markup.</p>
        HTML

      def parse(document_or_html)
        document_or_html ||= ''
        if document_or_html.is_a?(String)
          Nokogiri::HTML5::DocumentFragment.parse(document_or_html, max_tree_depth: HTML5_MAX_TREE_DEPTH)
        else
          document_or_html
        end
      rescue ArgumentError => e
        # We use an exact string match intentionally: we want to be very specific
        # about which ArgumentError we swallow, and our specs will catch any
        # (unlikely) change to this message in a Nokogiri version upgrade.
        raise unless e.message == TREE_DEPTH_LIMIT_ERROR

        Nokogiri::HTML5::DocumentFragment.parse(NESTING_TOO_DEEP_MESSAGE)
      end
    end
  end
end

HTML::Pipeline.singleton_class.prepend(HTML::Pipeline::HTML5Patch)
