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

            img_width = sizeParameters['wi'].to_i
            img_height = sizeParameters['he'].to_i
            if img_width > img_height
              aspect = img_height / (img_width * 0.01)
              img['style'] = '' << "height:0;padding-bottom:#{aspect}%"
            else
              aspect = img_width / (img_height * 0.01)
              img['style'] = '' << "width:0;padding-right:#{aspect}%"
            end
          end
        end

        doc
      end
    end
  end
end
