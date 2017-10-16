module Banzai
  module Filter
    # HTML filter that moves the value of image `src` attributes to `data-src`
    # so they can be lazy loaded.
    class ImageLazyLoadFilter < HTML::Pipeline::Filter
      def call
        doc.xpath('descendant-or-self::img').each do |img|
          img['class'] ||= '' << 'lazy'
          unless img['src'].nil? || img['src'].empty?
            begin
              url = URI.parse(img['src'])
              unless url.nil? || url.query.nil?
                size_parameters = CGI.parse(url.query)
                unless size_parameters['w'].empty? || size_parameters['h'].empty?
                  img_width = size_parameters['w'].first.to_i
                  img_height = size_parameters['h'].first.to_i

                  if img_width > 0 && img_height > 0
                    img['width'] = img_width
                    img['height'] = img_height
                    img['style'] = '' << calculate_aspect_ratio(img_width, img_height)
                  end
                end
              end
            rescue URI::InvalidURIError
            end

            img['data-src'] = img['src']
            img['src'] = LazyImageTagHelper.placeholder_image
          end
        end

        doc
      end

      def calculate_aspect_ratio(img_width, img_height)
        if img_width > img_height
          aspect_ratio = img_height / (img_width * 0.01)
          "height:0;padding-bottom:#{aspect_ratio}%"
        else
          aspect_ratio = img_width / (img_height * 0.01)
          "width:0;padding-right:#{aspect_ratio}%"
        end
      end
    end
  end
end
