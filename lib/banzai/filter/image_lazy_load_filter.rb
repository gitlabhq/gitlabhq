module Banzai
  module Filter
    # HTML filter that moves the value of image `src` attributes to `data-src`
    # so they can be lazy loaded.
    class ImageLazyLoadFilter < HTML::Pipeline::Filter
      def call
        doc.xpath('descendant-or-self::img').each do |img|
          img['class'] ||= '' << 'lazy'
          img['data-src'] = img['src']
          if img['src'].include?('?wi=')
            uri = URI.parse(img['src'])
            sizeParameters = URI.decode_www_form(uri.query).to_h
            img['width'] = sizeParameters['wi']
            img['height'] = sizeParameters['he']
          end
          img['src'] = LazyImageTagHelper.placeholder_image
        end

        doc
      end
    end
  end
end
