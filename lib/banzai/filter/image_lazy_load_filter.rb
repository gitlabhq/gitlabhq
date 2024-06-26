# frozen_string_literal: true

# Generated HTML is transformed back to GFM by app/assets/javascripts/behaviors/markdown/nodes/image.js
module Banzai
  module Filter
    # HTML filter that moves the value of image `src` attributes to `data-src`
    # so they can be lazy loaded. Also sets decoding to 'async' so that the
    # decoding of images doesn't block the loading of other content.
    class ImageLazyLoadFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck

      CSS   = 'img'
      XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS).freeze

      def call
        doc.xpath(XPATH).each do |img|
          img['decoding'] = 'async'
          img.add_class('lazy')
          img['data-src'] = img['src']
          img['src'] = LazyImageTagHelper.placeholder_image
        end

        doc
      end
    end
  end
end
