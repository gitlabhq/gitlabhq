# frozen_string_literal: true

module Banzai
  module Filter
    # Sanitize HTML produced by Markdown.
    #
    # Extends Banzai::Filter::BaseSanitizationFilter with specific rules.
    class SanitizationFilter < Banzai::Filter::BaseSanitizationFilter
      # Styles used by Markdown for table alignment
      TABLE_ALIGNMENT_PATTERN = /text-align: (?<alignment>center|left|right)/
      ALLOWED_IDIFF_CLASSES = %w[idiff left right deletion addition].freeze
      HEADER_NODE_NAMES = %w[h1 h2 h3 h4 h5 h6].freeze

      def customize_allowlist(allowlist)
        allowlist[:allow_comments] = context[:allow_comments]

        allow_table_alignment(allowlist)
        allow_json_table_attributes(allowlist)
        allow_sourcepos_and_escaped_char(allowlist)
        allow_id_attributes(allowlist)
        allow_class_attributes(allowlist)
        allow_section_footnotes(allowlist)
        allow_anchor_data_heading_content(allowlist)
        allow_tasklists(allowlist)

        allowlist
      end

      private

      def allow_table_alignment(allowlist)
        # Allow table alignment; we allow specific text-align values in a transformer below
        allowlist[:attributes]['th'] = %w[style]
        allowlist[:attributes]['td'] = %w[style]
        allowlist[:css] = { properties: ['text-align'] }

        # Remove any `style` properties not required for table alignment
        allowlist[:transformers].push(self.class.method(:remove_unsafe_table_style))
      end

      def allow_json_table_attributes(allowlist)
        # Allow json table attributes
        allowlist[:attributes]['table'] = %w[data-table-fields data-table-filter data-table-markdown]
      end

      def allow_sourcepos_and_escaped_char(allowlist)
        # Allow the 'data-sourcepos' from CommonMark on all elements
        allowlist[:attributes][:all].push('data-sourcepos')
        allowlist[:attributes][:all].push('data-escaped-char')
      end

      def allow_id_attributes(allowlist)
        # Allow `id` in `a` and `li` elements for footnotes and `h1`~`h6` elements for header anchors.
        # Remove any `id` properties not matching these patterns via transformer
        allowlist[:attributes]['a'].push('id')
        (["li"] + HEADER_NODE_NAMES).each do |tag|
          allowlist[:attributes][tag] = %w[id]
        end
        allowlist[:transformers].push(self.class.method(:remove_id_attributes))
      end

      def allow_class_attributes(allowlist)
        # Remove any `class` property not required for these elements via transformer
        allowlist[:attributes]['a'].push('class')
        allowlist[:attributes]['div'] = %w[class]
        allowlist[:attributes]['p'] = %w[class]
        allowlist[:attributes]['span'].push('class')
        allowlist[:attributes]['code'].push('class')
        allowlist[:attributes]['ul'] = %w[class]
        allowlist[:attributes]['ol'] = %w[class]
        allowlist[:attributes]['li'].push('class')
        allowlist[:attributes]['input'] = %w[class]
        allowlist[:transformers].push(self.class.method(:remove_unsafe_classes))
      end

      def allow_section_footnotes(allowlist)
        # Allow section elements with data-footnotes attribute and footnote-related anchors
        allowlist[:elements].push('section')
        allowlist[:attributes]['section'] = %w[data-footnotes]
        allowlist[:attributes]['a'].push('data-footnote-ref', 'data-footnote-backref', 'data-footnote-backref-idx')
      end

      def allow_anchor_data_heading_content(allowlist)
        allowlist[:attributes]['a'].push('data-heading-content')
      end

      def allow_tasklists(allowlist)
        allowlist[:elements].push('input')
        allowlist[:attributes]['input'].push('data-inapplicable')
        allowlist[:transformers].push(self.class.method(:remove_non_tasklist_inputs))
      end

      class << self
        def remove_unsafe_table_style(env)
          node = env[:node]

          return unless node.name == 'th' || node.name == 'td'
          return unless node.has_attribute?('style')

          if node['style'] =~ TABLE_ALIGNMENT_PATTERN
            node['style'] = "text-align: #{$~[:alignment]}"
          else
            node.remove_attribute('style')
          end
        end

        def remove_unsafe_classes(env) # rubocop:disable Metrics/CyclomaticComplexity -- dispatch method.
          node = env[:node]

          return unless node.has_attribute?('class')

          case node.name
          when 'a'
            node.remove_attribute('class') if remove_link_class?(node)
          when 'div'
            node.remove_attribute('class') if remove_div_class?(node)
          when 'p'
            node.remove_attribute('class') if remove_p_class?(node)
          when 'span'
            node.remove_attribute('class') if remove_span_class?(node)
          when 'code'
            node.remove_attribute('class') if remove_code_class?(node)
          when 'ul', 'ol'
            node.remove_attribute('class') if remove_ul_ol_class?(node)
          when 'li'
            node.remove_attribute('class') if remove_li_class?(node)
          when 'input'
            node.remove_attribute('class') if remove_input_class?(node)
          end
        end

        def remove_link_class?(node)
          node['class'] != 'anchor'
        end

        def remove_div_class?(node)
          node['class'] != 'markdown-alert markdown-alert-note' &&
            node['class'] != 'markdown-alert markdown-alert-tip' &&
            node['class'] != 'markdown-alert markdown-alert-important' &&
            node['class'] != 'markdown-alert markdown-alert-warning' &&
            node['class'] != 'markdown-alert markdown-alert-caution'
        end

        def remove_p_class?(node)
          node['class'] != 'markdown-alert-title'
        end

        def remove_span_class?(node)
          return true unless node['class'].include?('idiff')

          (node['class'].split - ALLOWED_IDIFF_CLASSES).present?
        end

        def remove_code_class?(node)
          node['class'] != 'idiff'
        end

        def remove_ul_ol_class?(node)
          node['class'] != 'task-list'
        end

        def remove_li_class?(node)
          node['class'] != 'task-list-item' &&
            node['class'] != 'inapplicable task-list-item'
        end

        def remove_input_class?(node)
          node['class'] != 'task-list-item-checkbox'
        end

        def remove_id_attributes(env)
          node = env[:node]
          return unless node.has_attribute?('id')

          id = node['id']

          case node.name
          when 'a'
            # footnote ids should not be removed
            return if id.start_with?(Banzai::Filter::FootnoteFilter::FOOTNOTE_LINK_ID_PREFIX)
          when 'li'
            # footnote ids should not be removed
            return if id.start_with?(Banzai::Filter::FootnoteFilter::FOOTNOTE_ID_PREFIX)
          when *HEADER_NODE_NAMES
            # headers with generated header anchors should not be removed
            return if id.start_with?(Banzai::Renderer::USER_CONTENT_ID_PREFIX)
          else
            return
          end

          node.remove_attribute('id')
        end

        def remove_non_tasklist_inputs(env)
          node = env[:node]

          return unless node.name == 'input'

          return if node['type'] == 'checkbox' && node['class'] == 'task-list-item-checkbox' && node.parent.name == 'li'

          node.remove
        end
      end
    end
  end
end

Banzai::Filter::SanitizationFilter.prepend_mod_with('Banzai::Filter::SanitizationFilter')
