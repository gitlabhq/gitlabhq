module Banzai
  module Filter
    # HTML filter that moves the value of image `src` attributes to `data-src`
    # so they can be lazy loaded.
    class ImageLazyLoadFilter < HTML::Pipeline::Filter
      def call
        doc.xpath('descendant-or-self::img').each do |img|
          img['class'] ||= '' << 'lazy'
          unless img['src'].empty? 
            img['data-src'] = img['src']
            begin
              size_parameters = CGI.parse(URI.parse(img['src']).query)
              unless size_parameters['w'].empty? || size_parameters['h'].empty?
                img_width = size_parameters['w'].first.to_i
                img_height = size_parameters['h'].first.to_i
  
                img['width'] = img_width
                img['height'] = img_height
  
                if img_width > 0 && img_height > 0
                  if img_width > img_height
                    aspect_ratio = img_height / (img_width * 0.01)
                    img['style'] = '' << "height:0;padding-bottom:#{aspect_ratio}%"
                  else
                    aspect_ratio = img_width / (img_height * 0.01)
                    img['style'] = '' << "width:0;padding-right:#{aspect_ratio}%"
                  end
                end
              end
            rescue URI::InvalidURIError              
            end
          end
        end

        doc
      end
    end
  end
end
