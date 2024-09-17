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

          # Allow data-escaped-chars span attribute
          allowlist[:attributes]['span'].push('data-escaped-chars')

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

          allowlist[:attributes]['img'].push('data-diagram')
          allowlist[:attributes]['img'].push('data-diagram-src')

          # Allow any protocol in `a` elements
          # and then remove links with unsafe protocols in SanitizeLinkFilter
          allowlist[:protocols].delete('a')

          # Remove `rel` attribute from `a` elements
          allowlist[:transformers].push(self.class.remove_rel)

          customize_allowlist(allowlist)
        end
      end

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
        HTML::Pipeline.parse(COMPLEX_MARKDOWN_MESSAGE)
      end

      class << self
        def remove_rel
          ->(env) do
            if env[:node_name] == 'a'
              # we allow rel="license" to support the Rel-license microformat
              # http://microformats.org/wiki/rel-license
              unless env[:node].attribute('rel')&.value == 'license'
                env[:node].remove_attribute('rel')
              end
            end
          end
        end
      end
    end
  end
end
