# frozen_string_literal: true

module Banzai
  module Filter
    # Adds heading IDs and anchor links to markup output
    # that don't natively generate heading IDs (Org-mode, MediaWiki, etc.),
    # as well as preserving existing IDs from markup that does (RDoc, etc.)
    #
    # This enables the table of contents navigation in the blob viewer.
    #
    # Input (org-ruby output):
    #   <h1>My Heading</h1>
    #
    # Output:
    #   <h1 id="user-content-my-heading">My Heading<a class="anchor" href="#my-heading"></a></h1>
    #
    # - Heading ids are prefixed with `user-content-`; SanitizationFilter strips ids without it.
    # - The anchor <a> needs class=anchor; SanitizationFilter strips <a> tags without it.
    # - The anchor's href omits the prefix to match Markdown behavior;
    #   JavaScript (handleLocationHash) resolves the resulting id/href mismatch.
    class MarkupHeadingAnchorFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck
      include ::Gitlab::Utils::StrongMemoize

      HEADER_CSS = 'h1, h2, h3, h4, h5, h6'
      HEADER_XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(HEADER_CSS).freeze

      def call
        used_slugs = {}

        doc.xpath(HEADER_XPATH).each do |heading|
          annotate_heading(heading, used_slugs, doc)
        end

        doc
      end

      private

      def annotate_heading(heading, used_slugs, doc)
        text_content = heading.text.strip

        # Derive slug from existing id or generate from heading text.
        slug = if heading.has_attribute?('id')
                 existing_id = heading['id']
                 return if existing_id.start_with?(Banzai::Renderer::USER_CONTENT_ID_PREFIX)

                 used_slugs[existing_id] ||= 0
                 existing_id
               else
                 return if text_content.blank?

                 generate_unique_slug(text_content, heading.name, used_slugs)
               end

        heading.set_attribute('id', "#{Banzai::Renderer::USER_CONTENT_ID_PREFIX}#{slug}")
        heading.add_child(doc.document.create_element('a',
          class: 'anchor',
          href: "##{slug}",
          'aria-label': "Link to heading '#{text_content}'",
          'data-heading-content': text_content
        ))
      end

      def generate_unique_slug(text, heading_name, used_slugs)
        # Fall back to tag name when the slug is blank
        base_slug = generate_slug(text).presence || heading_name
        base_slug = "#{filename_prefix}#{base_slug}" if filename_prefix

        if used_slugs.key?(base_slug)
          used_slugs[base_slug] += 1
          "#{base_slug}-#{used_slugs[base_slug]}"
        else
          used_slugs[base_slug] = 0
          base_slug
        end
      end

      def filename_prefix
        path = context[:requested_path] if context[:use_filename_in_anchor]
        return unless path

        name = File.basename(path, File.extname(path))

        slug = generate_slug(name)
        return if slug.blank?

        "#{slug}-"
      end
      strong_memoize_attr :filename_prefix

      # Mimics Comrak's anchorize(): https://github.com/kivikakk/comrak/blob/v0.52.0/src/html/anchorizer.rs
      def generate_slug(text)
        text.downcase
          .gsub(/[^\p{L}\p{M}\p{N}\p{Pc} -]/, '')
          .tr(' ', '-')
      end
    end
  end
end
