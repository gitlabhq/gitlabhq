# frozen_string_literal: true

module Banzai
  module Filter
    # Sanitize a single line of text or HTML produced by Markdown.
    class MinimumMarkdownSanitizationFilter < Banzai::Filter::BaseSanitizationFilter
      prepend Concerns::TimeoutFilterHandler
      include Gitlab::Utils::StrongMemoize

      # These are the basic inline markdown features. We support autolinking, so
      # allow limited protocols for `a`
      ALLOWLIST = {
        elements: %w[em strong code del a],
        attributes: { 'a' => ['href'] },
        remove_contents: ['script'],
        protocols: { 'a' => { 'href' => %w[http https] } }
      }.freeze

      def call
        Sanitize.clean_node!(doc, allowlist)

        # The markdown filter always wraps it's output in a `<p>` tag.
        # The sanitizer will turn it into a text node of space. So let's remove
        # the leading and trailing spaces if it exists.
        if doc.children.present?
          doc.children.first.remove if doc.children.first.blank?
          doc.children.last.remove if doc.children.last.blank?
        end

        doc
      end

      # This completely overrides the BaseSanitizationFilter allowlist. We don't
      # want to support math, spans, etc. Bare minimum markdown
      def allowlist
        ALLOWLIST
      end
      strong_memoize_attr :allowlist
    end
  end
end
