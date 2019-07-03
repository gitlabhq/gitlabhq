# frozen_string_literal: true

module Banzai
  module Filter
    # Sanitize HTML
    #
    # Extends HTML::Pipeline::SanitizationFilter with a custom whitelist.
    class SanitizationFilter < HTML::Pipeline::SanitizationFilter
      include Gitlab::Utils::StrongMemoize
      extend Gitlab::Utils::SanitizeNodeLink

      TABLE_ALIGNMENT_PATTERN = /text-align: (?<alignment>center|left|right)/.freeze

      def whitelist
        strong_memoize(:whitelist) do
          customize_whitelist(super.deep_dup)
        end
      end

      private

      def customize_whitelist(whitelist)
        # Allow table alignment; we whitelist specific text-align values in a
        # transformer below
        whitelist[:attributes]['th'] = %w(style)
        whitelist[:attributes]['td'] = %w(style)
        whitelist[:css] = { properties: ['text-align'] }

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

        # Allow the 'data-sourcepos' from CommonMark on all elements
        whitelist[:attributes][:all].push('data-sourcepos')

        # Disallow `name` attribute globally, allow on `a`
        whitelist[:attributes][:all].delete('name')
        whitelist[:attributes]['a'].push('name')

        # Allow any protocol in `a` elements
        # and then remove links with unsafe protocols
        whitelist[:protocols].delete('a')
        whitelist[:transformers].push(self.class.method(:remove_unsafe_links))

        # Remove `rel` attribute from `a` elements
        whitelist[:transformers].push(self.class.remove_rel)

        # Remove any `style` properties not required for table alignment
        whitelist[:transformers].push(self.class.remove_unsafe_table_style)

        # Allow `id` in a and li elements for footnotes
        # and remove any `id` properties not matching for footnotes
        whitelist[:attributes]['a'].push('id')
        whitelist[:attributes]['li'] = %w(id)
        whitelist[:transformers].push(self.class.remove_non_footnote_ids)

        whitelist
      end

      class << self
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

        def remove_non_footnote_ids
          lambda do |env|
            node = env[:node]

            return unless node.name == 'a' || node.name == 'li'
            return unless node.has_attribute?('id')

            return if node.name == 'a' && node['id'] =~ Banzai::Filter::FootnoteFilter::FOOTNOTE_LINK_REFERENCE_PATTERN
            return if node.name == 'li' && node['id'] =~ Banzai::Filter::FootnoteFilter::FOOTNOTE_LI_REFERENCE_PATTERN

            node.remove_attribute('id')
          end
        end
      end
    end
  end
end
