# frozen_string_literal: true

# Generated HTML is transformed back to GFM by app/assets/javascripts/behaviors/markdown/nodes/image.js
module Banzai
  module Filter
    # HTML filter that wraps links around inline images.
    class ImageLinkFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck

      # Find every image that isn't already wrapped in an `a` tag, create
      # a new node (a link to the image source), copy the image as a child
      # of the anchor, and then replace the img with the link-wrapped version.
      #
      # If `link_replaces_image` context parameter is provided, the image is going
      # to be replaced with a link to an image.
      def call
        doc.xpath('descendant-or-self::img[not(ancestor::a) and not(@data-src = "")]').each do |img|
          link_replaces_image = !!context[:link_replaces_image]
          html_class = link_replaces_image ? 'with-attachment-icon' : 'no-attachment-icon'

          link = doc.document.create_element(
            'a',
            class: html_class,
            href: img['data-src'] || img['src'],
            target: '_blank',
            rel: 'noopener noreferrer'
          )

          # make sure the original non-proxied src carries over to the link
          link['data-canonical-src'] = img['data-canonical-src'] if img['data-canonical-src']

          if img['data-diagram'] && img['data-diagram-src']
            link['data-diagram'] = img['data-diagram']
            link['data-diagram-src'] = img['data-diagram-src']
            img.remove_attribute('data-diagram')
            img.remove_attribute('data-diagram-src')
          end

          link.children = link_replaces_image ? link_children(img) : img.clone

          img.replace(link)
        end

        doc
      end

      private

      def link_children(img)
        [img['alt'], img['data-src'], img['src']]
          .map { |f| Sanitize.fragment(f).presence }.compact.first || ''
      end
    end
  end
end
