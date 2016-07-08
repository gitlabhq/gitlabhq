module Banzai
  module Filter

    # HTML Filter that handles video uploads.

    class VideoLinkFilter < HTML::Pipeline::Filter
      include ActionView::Helpers::TagHelper
      include ActionView::Context

      def call
        doc.search('img').each do |el|
          el.replace(video_tag(doc, el)) if video?(el)
        end

        doc
      end

      private

      def video?(element)
        extension = File.extname(element.attribute('src').value).delete('.')
        UploaderHelper::VIDEO_EXT.include?(extension)
      end

      # Return a video tag Nokogiri node
      #
      def video_node(doc, element)
        doc.document.create_element(
          'video',
          src: element.attribute('src').value,
          class: 'video-js',
          controls: true)
      end
    end

  end
end
