# frozen_string_literal: true

module Banzai
  module Filter
    # Sanitize HTML produced by AsciiDoc/Asciidoctor.
    #
    # Extends Banzai::Filter::BaseSanitizationFilter with specific rules.
    class AsciiDocSanitizationFilter < Banzai::Filter::BaseSanitizationFilter
      # Classes used by Asciidoctor to style components
      ADMONITION_CLASSES = %w(fa icon-note icon-tip icon-warning icon-caution icon-important).freeze
      CALLOUT_CLASSES = ['conum'].freeze
      CHECKLIST_CLASSES = %w(fa fa-check-square-o fa-square-o).freeze

      LIST_CLASSES = %w(checklist none no-bullet unnumbered unstyled).freeze

      ELEMENT_CLASSES_WHITELIST = {
        span: %w(big small underline overline line-through).freeze,
        div: ['admonitionblock'].freeze,
        td: ['icon'].freeze,
        i: ADMONITION_CLASSES + CALLOUT_CLASSES + CHECKLIST_CLASSES,
        ul: LIST_CLASSES,
        ol: LIST_CLASSES
      }.freeze

      def customize_whitelist(whitelist)
        # Allow marks
        whitelist[:elements].push('mark')

        # Allow any classes in `span`, `i`, `div`, `td`, `ul` and `ol` elements
        # but then remove any unknown classes
        whitelist[:attributes]['span'] = %w(class)
        whitelist[:attributes]['div'].push('class')
        whitelist[:attributes]['td'] = %w(class)
        whitelist[:attributes]['i'] = %w(class)
        whitelist[:attributes]['ul'] = %w(class)
        whitelist[:attributes]['ol'] = %w(class)
        whitelist[:transformers].push(self.class.remove_element_classes)

        whitelist
      end

      class << self
        def remove_element_classes
          lambda do |env|
            node = env[:node]

            return unless (classes_whitelist = ELEMENT_CLASSES_WHITELIST[node.name.to_sym])
            return unless node.has_attribute?('class')

            classes = node['class'].strip.split(' ')
            allowed_classes = (classes & classes_whitelist)
            if allowed_classes.empty?
              node.remove_attribute('class')
            else
              node['class'] = allowed_classes.join(' ')
            end
          end
        end
      end
    end
  end
end
