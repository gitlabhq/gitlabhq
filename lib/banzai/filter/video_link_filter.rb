module Banzai
  module Filter

    # HTML Filter that handles video uploads.

    class VideoLinkFilter < HTML::Pipeline::Filter
      include ActionView::Helpers::TagHelper
      include ActionView::Context

      EXTENSIONS = %w(.mov .mp4 .ogg .webm .flv)

      def call
        doc.search('img').each do |el|
          if video?(el)
            el.replace video_node(el)
          end
        end

        doc
      end

      private

      def video?(element)
        EXTENSIONS.include? File.extname(element.attribute('src').value)
      end

      # Return a video tag Nokogiri node
      #
      def video_node(element)
        vtag = content_tag(:video, "", {
                            src: element.attribute('src').value,
                            class: 'video-js', preload: 'auto',
                            controls: true
                            })

        Nokogiri::HTML::DocumentFragment.parse(vtag)
      end
    end

  end
end
