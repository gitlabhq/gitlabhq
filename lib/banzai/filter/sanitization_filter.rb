module Banzai
  module Filter
    # Sanitize HTML
    #
    # Extends HTML::Pipeline::SanitizationFilter with a custom whitelist.
    class SanitizationFilter < HTML::Pipeline::SanitizationFilter
      UNSAFE_PROTOCOLS = %w(data javascript vbscript).freeze

      def whitelist
        whitelist = super

        customize_whitelist(whitelist)

        whitelist
      end

      private

      def customized?(transformers)
        transformers.last.source_location[0] == __FILE__
      end

      def customize_whitelist(whitelist)
        # Only push these customizations once
        return if customized?(whitelist[:transformers])

        # Allow table alignment
        whitelist[:attributes]['th'] = %w(style)
        whitelist[:attributes]['td'] = %w(style)

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

        # Allow any protocol in `a` elements...
        whitelist[:protocols].delete('a')

        # ...but then remove links with unsafe protocols
        whitelist[:transformers].push(self.class.remove_unsafe_links)

        # Remove `rel` attribute from `a` elements
        whitelist[:transformers].push(self.class.remove_rel)

        whitelist
      end

      class << self
        def remove_unsafe_links
          lambda do |env|
            node = env[:node]

            return unless node.name == 'a'
            return unless node.has_attribute?('href')

            begin
              uri = Addressable::URI.parse(node['href'])
              uri.scheme = uri.scheme.strip.downcase if uri.scheme

              node.remove_attribute('href') if UNSAFE_PROTOCOLS.include?(uri.scheme)
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
