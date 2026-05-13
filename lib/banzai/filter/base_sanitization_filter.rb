# frozen_string_literal: true

module Banzai
  module Filter
    # Sanitize HTML produced by markup languages (Markdown, AsciiDoc...).
    # Specific rules are implemented in dedicated filters:
    #
    # - Banzai::Filter::SanitizationFilter (Markdown)
    # - Banzai::Filter::AsciiDocSanitizationFilter (AsciiDoc/Asciidoctor)
    # - Banzai::Filter::BroadcastMessageSanitizationFilter (Markdown with styled links and line breaks)
    #
    # Extends HTML::Pipeline::SanitizationFilter with common rules.
    class BaseSanitizationFilter < HTML::Pipeline::SanitizationFilter
      prepend Concerns::TimeoutFilterHandler
      include Gitlab::Utils::StrongMemoize
      extend Gitlab::Utils::SanitizeNodeLink

      UNSAFE_PROTOCOLS = %w[data javascript vbscript].freeze

      def call
        Sanitize.clean_node!(doc, allowlist)
      end

      # rubocop:disable Metrics/AbcSize -- Our allowlist is complicated.
      def allowlist
        strong_memoize(:allowlist) do
          allowlist = super.deep_dup

          # Allow span elements
          allowlist[:elements].push('span')

          # Allow data-math-style attribute in order to support LaTeX formatting
          allowlist[:attributes]['span'] = %w[data-math-style]
          allowlist[:attributes]['code'] = %w[data-math-style]
          allowlist[:attributes]['pre'] = %w[data-canonical-lang data-lang-params
            data-math-style data-mermaid-style data-kroki-style]

          # Allow data-placeholder from gitlab-glfm-markdown
          allowlist[:attributes]['span'].push('data-placeholder')

          # Allow html5 details/summary elements
          allowlist[:elements].push('details')
          allowlist[:elements].push('summary')

          # Allow abbr elements with title attribute
          allowlist[:elements].push('abbr')
          allowlist[:attributes]['abbr'] = %w[title]

          # Disallow `name` attribute globally, allow on `a`
          allowlist[:attributes][:all].delete('name')
          allowlist[:attributes]['a'].push('name')

          allowlist[:attributes]['a'].push('data-wikilink')
          allowlist[:attributes]['a'].push('data-placeholder')

          allowlist[:attributes]['img'].push('data-diagram')
          allowlist[:attributes]['img'].push('data-diagram-src')
          allowlist[:attributes]['img'].push('data-placeholder')

          # Allow any protocol in `a` elements
          # and then remove links with unsafe protocols in SanitizeLinkFilter
          allowlist[:protocols].delete('a')

          # Remove `rel` attribute from `a` elements
          allowlist[:transformers].push(self.class.method(:remove_rel))

          # Unwrap <a> tags nested within other <a> tags.
          #
          # Nested <a> tags are invalid HTML, but the HTML5 parser can produce
          # them in several ways: table foster-parenting (`<a><table><a>`),
          # foreign content (`<a><svg><a>`, `<a><math><a>`), and
          # `<a><template><a>`. In all these cases an inner <a> ends up as a
          # descendant of an outer <a> in the DOM.
          #
          # This is a security concern because later pipeline filters
          # (ReferenceFilter, ReferenceRedactor) operate on <a> nodes
          # independently. A nested <a> that resolves as a reference can have
          # its content captured in the outer <a>'s data-original attribute. If
          # the outer link is to a resource the viewer can access but the inner
          # reference is to one they cannot, the redactor will leave the outer
          # <a> intact, along with its data-original; this leaks the resolved
          # content of the inner reference the viewer should not see.
          allowlist[:transformers].push(self.class.method(:unwrap_nested_a))

          allowlist = customize_allowlist(allowlist)

          # The HTML5 parser creates namespaced attributes (e.g. xlink:href) inside SVG
          # and MathML foreign content. A namespaced attribute can share its local name
          # with an existing HTML attribute on the same element (e.g. both href and
          # xlink:href have local name "href"), and Nokogiri's attribute accessor and
          # mutator methods will only affect one at a time, potentially letting dangerous
          # values survive sanitisation.
          #
          # Strip every namespaced attribute before any other transformer runs so the rest
          # of the pipeline sees only simple, unambiguous HTML attributes.
          allowlist[:transformers].unshift(self.class.method(:remove_namespaced_attributes))

          allowlist
        end
      end
      # rubocop:enable Metrics/AbcSize

      def customize_allowlist(allowlist)
        raise NotImplementedError
      end

      private

      def render_timeout
        SANITIZATION_RENDER_TIMEOUT
      end

      # If sanitization times out, we can not return partial un-sanitized results.
      # It's ok to allow any following filters to run since this is safe HTML.
      def returned_timeout_value
        Banzai::PipelineBase.parse(COMPLEX_MARKDOWN_MESSAGE)
      end

      class << self
        def remove_rel(env)
          return unless env[:node_name] == 'a'
          # we allow rel="license" to support the Rel-license microformat
          # http://microformats.org/wiki/rel-license
          return if env[:node].attribute('rel')&.value == 'license'

          env[:node].remove_attribute('rel')
        end

        # Replaces a nested <a> with its children, preserving the text content
        # but removing the inner link. This is safe because nested <a> tags are
        # not valid HTML to begin with; browsers would never render them nested,
        # so we don't lose any meaningful structure.
        def unwrap_nested_a(env)
          node = env[:node]
          return unless node.element? && node.name == 'a'
          return unless node.ancestors.any? { |ancestor| ancestor.element? && ancestor.name == 'a' }

          node.replace(node.children)
        end

        def remove_namespaced_attributes(env)
          env[:node].attribute_nodes.each do |attr|
            attr.remove if attr.namespace
          end
        end
      end
    end
  end
end
