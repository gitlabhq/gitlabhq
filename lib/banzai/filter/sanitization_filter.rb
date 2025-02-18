# frozen_string_literal: true

module Banzai
  module Filter
    # Sanitize HTML produced by Markdown.
    #
    # Extends Banzai::Filter::BaseSanitizationFilter with specific rules.
    class SanitizationFilter < Banzai::Filter::BaseSanitizationFilter
      # Styles used by Markdown for table alignment
      TABLE_ALIGNMENT_PATTERN = /text-align: (?<alignment>center|left|right)/

      def customize_allowlist(allowlist)
        allowlist[:allow_comments] = context[:allow_comments]

        # Allow table alignment; we allow specific text-align values in a
        # transformer below
        allowlist[:attributes]['th'] = %w[style]
        allowlist[:attributes]['td'] = %w[style]
        allowlist[:css] = { properties: ['text-align'] }

        # Allow json table attributes
        allowlist[:attributes]['table'] = %w[data-table-fields data-table-filter data-table-markdown]

        # Allow the 'data-sourcepos' from CommonMark on all elements
        allowlist[:attributes][:all].push('data-sourcepos')
        allowlist[:attributes][:all].push('data-escaped-char')

        # Remove any `style` properties not required for table alignment
        allowlist[:transformers].push(self.class.remove_unsafe_table_style)

        # Allow `id` in `a` and `li` elements for footnotes
        # and `a` elements for header anchors.
        # Remove any `id` properties not matching
        allowlist[:attributes]['a'].push('id')
        allowlist[:attributes]['li'] = %w[id]
        allowlist[:transformers].push(self.class.remove_id_attributes)

        # Remove any `class` property not required for `a`
        allowlist[:attributes]['a'].push('class')
        allowlist[:transformers].push(self.class.remove_unsafe_link_class)

        # Allow section elements with data-footnotes attribute
        allowlist[:elements].push('section')
        allowlist[:attributes]['section'] = %w[data-footnotes]
        allowlist[:attributes]['a'].push('data-footnote-ref', 'data-footnote-backref', 'data-footnote-backref-idx')

        allowlist
      end

      class << self
        def remove_unsafe_table_style
          ->(env) do
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

        def remove_unsafe_link_class
          ->(env) do
            node = env[:node]

            return unless node.name == 'a'
            return unless node.has_attribute?('class')

            node.remove_attribute('class') if remove_link_class?(node)
          end
        end

        def remove_link_class?(node)
          return if node['class'] == 'anchor'

          true
        end

        def remove_id_attributes
          ->(env) do
            node = env[:node]

            return unless node.name == 'a' || node.name == 'li'
            return unless node.has_attribute?('id')

            # footnote ids should not be removed
            return if node.name == 'li' && node['id'].start_with?(Banzai::Filter::FootnoteFilter::FOOTNOTE_ID_PREFIX)
            return if node.name == 'a' &&
              node['id'].start_with?(Banzai::Filter::FootnoteFilter::FOOTNOTE_LINK_ID_PREFIX)

            # links with generated header anchors should not be removed
            return if node.name == 'a' && node['class'] == 'anchor' &&
              node['id'].start_with?(Banzai::Renderer::USER_CONTENT_ID_PREFIX)

            node.remove_attribute('id')
          end
        end
      end
    end
  end
end

Banzai::Filter::SanitizationFilter.prepend_mod_with('Banzai::Filter::SanitizationFilter')
