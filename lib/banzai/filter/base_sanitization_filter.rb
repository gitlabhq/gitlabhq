# frozen_string_literal: true

module Banzai
  module Filter
    # Sanitize HTML produced by markup languages (Markdown, AsciiDoc...).
    # Specific rules are implemented in dedicated filters:
    #
    # - Banzai::Filter::SanitizationFilter (Markdown)
    # - Banzai::Filter::AsciiDocSanitizationFilter (AsciiDoc/Asciidoctor)
    #
    # Extends HTML::Pipeline::SanitizationFilter with common rules.
    class BaseSanitizationFilter < HTML::Pipeline::SanitizationFilter
      include Gitlab::Utils::StrongMemoize

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
          whitelist[:transformers].push(self.class.remove_unsafe_links)

          # Remove `rel` attribute from `a` elements
          whitelist[:transformers].push(self.class.remove_rel)

          customize_whitelist(whitelist)
        end
      end

      def customize_whitelist(whitelist)
        raise NotImplementedError
      end

      class << self
        def remove_unsafe_links
          lambda do |env|
            node = env[:node]

            return unless node.name == 'a'
            return unless node.has_attribute?('href')

            begin
              node['href'] = node['href'].strip
              uri = Addressable::URI.parse(node['href'])

              return unless uri.scheme

              # Remove all invalid scheme characters before checking against the
              # list of unsafe protocols.
              #
              # See https://tools.ietf.org/html/rfc3986#section-3.1
              scheme = uri.scheme
                           .strip
                           .downcase
                           .gsub(/[^A-Za-z0-9\+\.\-]+/, '')

              node.remove_attribute('href') if UNSAFE_PROTOCOLS.include?(scheme)
            rescue Addressable::URI::InvalidURIError
              node.remove_attribute('href')
            end
          end
        end

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
