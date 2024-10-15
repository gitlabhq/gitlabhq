# frozen_string_literal: true

module Banzai
  module Filter
    # Sanitize HTML produced by AsciiDoc/Asciidoctor.
    #
    # Extends Banzai::Filter::BaseSanitizationFilter with specific rules.
    class AsciiDocSanitizationFilter < Banzai::Filter::BaseSanitizationFilter
      # Anchor link prefixed by "user-content-" pattern
      PREFIXED_ID_PATTERN = /\A#{Gitlab::Asciidoc::DEFAULT_ADOC_ATTRS['idprefix']}(:?[[:alnum:]]|-|_)+\z/
      SECTION_HEADINGS = %w[h2 h3 h4 h5 h6].freeze

      # Footnote link patterns
      FOOTNOTE_LINK_ID_PATTERNS = {
        a: /\A_footnoteref_\d+\z/,
        div: /\A_footnotedef_\d+\z/
      }.freeze

      # Classes used by Asciidoctor to style components
      ADMONITION_CLASSES = %w[fa icon-note icon-tip icon-warning icon-caution icon-important].freeze
      ALIGNMENT_BUILTINS_CLASSES = %w[text-center text-left text-right text-justify].freeze
      CALLOUT_CLASSES = ['conum'].freeze
      CHECKLIST_CLASSES = %w[fa fa-check-square-o fa-square-o].freeze
      LIST_CLASSES = %w[checklist none no-bullet unnumbered unstyled].freeze

      TABLE_FRAME_CLASSES = %w[frame-all frame-topbot frame-sides frame-ends frame-none].freeze
      TABLE_GRID_CLASSES = %w[grid-all grid-rows grid-cols grid-none].freeze
      TABLE_STRIPES_CLASSES = %w[stripes-all stripes-odd stripes-even stripes-hover stripes-none].freeze

      ELEMENT_CLASSES_ALLOWLIST = {
        span: %w[big small underline overline line-through].freeze,
        div: ALIGNMENT_BUILTINS_CLASSES + %w[openblock exampleblock sidebarblock admonitionblock].freeze,
        td: ['icon'].freeze,
        i: ADMONITION_CLASSES + CALLOUT_CLASSES + CHECKLIST_CLASSES,
        ul: LIST_CLASSES,
        ol: LIST_CLASSES,
        a: ['anchor'].freeze,
        table: TABLE_FRAME_CLASSES + TABLE_GRID_CLASSES + TABLE_STRIPES_CLASSES
      }.freeze

      def customize_allowlist(allowlist)
        # Allow marks
        allowlist[:elements].push('mark')

        # Allow any classes in `span`, `i`, `div`, `td`, `ul`, `ol` and `a` elements
        # but then remove any unknown classes
        allowlist[:attributes]['span'] = %w[class]
        allowlist[:attributes]['div'].push('class')
        allowlist[:attributes]['td'] = %w[class]
        allowlist[:attributes]['i'] = %w[class]
        allowlist[:attributes]['ul'] = %w[class]
        allowlist[:attributes]['ol'] = %w[class]
        allowlist[:attributes]['a'].push('class')
        allowlist[:attributes]['table'] = %w[class]
        allowlist[:transformers].push(self.class.remove_element_classes)

        # Allow `id` in anchor and footnote elements
        allowlist[:attributes]['a'].push('id')
        allowlist[:attributes]['div'].push('id')

        # Allow `id` in heading elements for section anchors
        SECTION_HEADINGS.each do |header|
          allowlist[:attributes][header] = %w[id]
        end

        # Remove ids that are not explicitly allowed
        allowlist[:transformers].push(self.class.remove_disallowed_ids)

        allowlist
      end

      class << self
        def remove_disallowed_ids
          ->(env) do
            node = env[:node]

            return unless node.name == 'a' || node.name == 'div' || SECTION_HEADINGS.any?(node.name)
            return unless node.has_attribute?('id')

            return if PREFIXED_ID_PATTERN.match?(node['id'])

            if (pattern = FOOTNOTE_LINK_ID_PATTERNS[node.name.to_sym])
              return if node['id']&.match?(pattern)
            end

            node.remove_attribute('id')
          end
        end

        def remove_element_classes
          ->(env) do
            node = env[:node]

            return unless (classes_allowlist = ELEMENT_CLASSES_ALLOWLIST[node.name.to_sym])
            return unless node.has_attribute?('class')

            classes = node['class'].strip.split(' ')
            allowed_classes = (classes & classes_allowlist)
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
