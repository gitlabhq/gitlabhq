module Banzai
  module Filter
    # Sanitize HTML
    #
    # Extends HTML::Pipeline::SanitizationFilter with a custom whitelist.
    class SanitizationFilter < HTML::Pipeline::SanitizationFilter
      UNSAFE_PROTOCOLS = %w(data javascript vbscript).freeze
      TABLE_ALIGNMENT_PATTERN = /text-align: (?<alignment>center|left|right)/

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

        # Allow table alignment; we whitelist specific style properties in a
        # transformer below
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

        # Disallow `name` attribute globally, allow on `a`
        whitelist[:attributes][:all].delete('name')
        whitelist[:attributes]['a'].push('name')

        # Allow any protocol in `a` elements...
        whitelist[:protocols].delete('a')

        # ...but then remove links with unsafe protocols
        whitelist[:transformers].push(self.class.remove_unsafe_links)

        # Remove `rel` attribute from `a` elements
        whitelist[:transformers].push(self.class.remove_rel)

        # Remove any `style` properties not required for table alignment
        whitelist[:transformers].push(self.class.remove_unsafe_table_style)

        whitelist
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

        def remove_unsafe_table_style
          lambda do |env|
            node = env[:node]

            return unless node.name == 'th' || node.name == 'td'
            return unless node.has_attribute?('style')

            if node['style'] =~ TABLE_ALIGNMENT_PATTERN
              node['style'] = "text-align: #{$~[:alignment]}"
            else
              node.remove_attribute('style')
            end
          end
        end
      end
    end
  end
end
