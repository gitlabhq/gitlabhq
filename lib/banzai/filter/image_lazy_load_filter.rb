module Banzai
  module Filter
    # HTML filter that moves the value of image `src` attributes to `data-src`
    # so they can be lazy loaded.
    class ImageLazyLoadFilter < HTML::Pipeline::Filter
      def call
        doc.xpath('descendant-or-self::img').each do |img|
          img['class'] ||= '' << 'lazy'
          unless img['src'].nil? || img['src'].empty?
            img['data-src'] = img['src']
            img['src'] = LazyImageTagHelper.placeholder_image

            begin
              url = URI.parse(img['data-src'])
              unless url.nil? || url.query.nil?
                size_parameters = CGI.parse(url.query)
                unless size_parameters['w'].empty? || size_parameters['h'].empty?
                  img_width = size_parameters['w'].first.to_i
                  img_height = size_parameters['h'].first.to_i

                  if img_width > 0 && img_height > 0
                    img['width'] = img_width
                    img['height'] = img_height
                    img['class'] << 'lazy-sized'

                    # We need to have a container around with actual aspect_ratio set to support responsive img's
                    if img.parent.name == 'a'
                      img.parent.style = '' << calculate_aspect_ratio(img_width, img_height)
                    else
                      img_container = doc.document.create_element(
                        'span',
                        class: 'rimg-container',
                        style: calculate_aspect_ratio(img_width, img_height)
                      )

                      img_container.children = img.clone
                      img.replace(img_container)
                    end
                    
                  end
                end
              end
            rescue URI::InvalidURIError
            end

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
