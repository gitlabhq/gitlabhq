# frozen_string_literal: true

# Generated HTML is transformed back to GFM by app/assets/javascripts/behaviors/markdown/nodes/image.js
module Banzai
  module Filter
    # HTML filter that wraps links around inline images.
    class ImageLinkFilter < HTML::Pipeline::Filter
      # Find every image that isn't already wrapped in an `a` tag, create
      # a new node (a link to the image source), copy the image as a child
      # of the anchor, and then replace the img with the link-wrapped version.
      def call
        doc.xpath('descendant-or-self::img[not(ancestor::a)]').each do |img|
          link = doc.document.create_element(
            'a',
            class: 'no-attachment-icon',
            href: img['data-src'] || img['src'],
            target: '_blank',
            rel: 'noopener noreferrer'
          )

          # make sure the original non-proxied src carries over to the link
          link['data-canonical-src'] = img['data-canonical-src'] if img['data-canonical-src']

          link.children = img.clone

          img.replace(link)
        end

        doc
      end
    end
  end
end
