# frozen_string_literal: true

module Banzai
  module Filter
    # HTML Filter for handling Gollum style wiki links. Links have already
    # been recognized and tagged with `data-wikilink="true"` by the markdown parser.
    # This filter adds our classes and checks if they are valid links,
    # and converts to image tags if they link to images.
    #
    # Currently supported syntax:
    # - Link to internal pages:
    #
    #   * [[Bug Reports]]
    #   * [[How to Contribute|Contributing]]
    #
    # - Link to external resources:
    #
    #   * [[http://en.wikipedia.org/wiki/Git_(software)]]
    #   * [[Git|http://en.wikipedia.org/wiki/Git_(software)]]
    #
    # - Link internal images, gollum special attributes not supported
    #
    #   * [[images/logo.png]]
    #
    # - Link external images, gollum special attributes not supported
    #
    #   * [[http://example.com/images/logo.png]]
    #
    class WikiLinkGollumFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck

      # Pattern to match allowed image extensions
      ALLOWED_IMAGE_EXTENSIONS = /(jpg|png|gif|svg|bmp)\z/i

      CSS_WIKILINK_STYLE = 'a[href][data-wikilink]'
      XPATH_WIKILINK_STYLE = Gitlab::Utils::Nokogiri.css_to_xpath(CSS_WIKILINK_STYLE).freeze

      IMAGE_LINK_LIMIT = 100

      def call
        @image_link_count = 0

        doc.xpath(XPATH_WIKILINK_STYLE).each_with_index do |node, index|
          break if Banzai::Filter.filter_item_limit_exceeded?(index)

          process_image_link(node) || process_page_link(node)
        end

        doc
      end

      private

      # Attempt to process the node as an image tag.
      def process_image_link(node)
        return unless image?(node[:href])

        # checking for the existence of an image file tends to be slow. So limit it.
        return if image_link_limit_exceeded?

        path =
          if url?(node[:href])
            node[:href]
          elsif wiki
            @image_link_count += 1
            wiki.find_file(node[:href], load_content: false)&.path
          end

        return unless path

        img = doc.document.create_element('img', class: 'gfm', src: path)

        node.replace(img)

        true
      end

      # Attempt to process the node as a page link tag.
      def process_page_link(node)
        return if node[:href].casecmp?('_toc_') && node.text.casecmp?('_toc_')

        if url?(node[:href])
          set_common_attributes(node)
        elsif wiki
          set_common_attributes(node)

          node[:href] = ::File.join(wiki_base_path, node[:href])
          node.add_class('gfm')
          node.add_class('gfm-gollum-wiki-page')

          node['data-reference-type'] = 'wiki_page'
          node['data-project'] = context[:project].id if context[:project]
          node['data-group'] = context[:group]&.id if context[:group]
        end
      end

      def set_common_attributes(node)
        node.add_class('gfm')
        node['data-canonical-src'] = node[:href]
        node['data-link'] = true
        node['data-gollum'] = true
      end

      def wiki
        context[:wiki] || context[:project]&.wiki || context[:group]&.wiki
      end

      def wiki_base_path
        wiki&.wiki_base_path
      end

      def image?(path)
        path =~ ALLOWED_IMAGE_EXTENSIONS
      end

      def url?(path)
        path.start_with?(*%w[http https])
      end

      def image_link_limit_exceeded?
        @image_link_count >= Banzai::Filter::WikiLinkGollumFilter::IMAGE_LINK_LIMIT
      end
    end
  end
end
