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
      include Gitlab::Utils::StrongMemoize
      extend Gitlab::Utils::SanitizeNodeLink

      UNSAFE_PROTOCOLS = %w(data javascript vbscript).freeze

      def whitelist
        strong_memoize(:whitelist) do
          whitelist = super.deep_dup

          # Allow span elements
          whitelist[:elements].push('span')

          # Allow data-math-style attribute in order to support LaTeX formatting
          whitelist[:attributes]['code'] = %w(data-math-style)
          whitelist[:attributes]['pre'] = %w(data-math-style)

          # Allow html5 details/summary elements
          whitelist[:elements].push('details')
          whitelist[:elements].push('summary')

          # Allow abbr elements with title attribute
          whitelist[:elements].push('abbr')
          whitelist[:attributes]['abbr'] = %w(title)

          # Disallow `name` attribute globally, allow on `a`
          whitelist[:attributes][:all].delete('name')
          whitelist[:attributes]['a'].push('name')

          # Allow any protocol in `a` elements
          # and then remove links with unsafe protocols
          whitelist[:protocols].delete('a')
          whitelist[:transformers].push(self.class.method(:remove_unsafe_links))

          # Remove `rel` attribute from `a` elements
          whitelist[:transformers].push(self.class.remove_rel)

          customize_whitelist(whitelist)
        end
      end

      def customize_whitelist(whitelist)
        raise NotImplementedError
      end

      class << self
        def remove_rel
          lambda do |env|
            if env[:node_name] == 'a'
              env[:node].remove_attribute('rel')
            end
          end
        end
      end
    end
  end
end
