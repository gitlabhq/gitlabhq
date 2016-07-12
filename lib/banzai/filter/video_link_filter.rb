module Banzai
  module Filter

    # HTML Filter that handles video uploads.

    class VideoLinkFilter < HTML::Pipeline::Filter
      include ActionView::Helpers::TagHelper
      include ActionView::Context

      def call
        doc.xpath(query).each do |el|
          el.replace(video_node(doc, el))
        end

        doc
      end

      private

      def query
        @query ||= begin
          src_query = UploaderHelper::VIDEO_EXT.map do |ext|
            "'.#{ext}' = substring(@src, string-length(@src) - #{ext.size})"
          end

          "descendant-or-self::img[not(ancestor::a) and (#{src_query.join(' or ')})]"
        end
      end

      # Return a video tag Nokogiri node
      #
      def video_node(doc, element)
        container = doc.document.create_element(
          'div',
          class: 'video-container'
        )

        video = doc.document.create_element(
          'video',
          src: element['src'],
          class: 'video-js vjs-sublime-skin',
          controls: true,
          "data-setup": '{}')

        link = doc.document.create_element(
          'a',
          element['title'] || element['alt'],
          href: element['src'],
          target: '_blank',
          title: "Downlad '#{element['title'] || element['alt']}'")
        download_paragraph = doc.document.create_element('p')
        download_paragraph.children = link

        container.add_child(video)
        container.add_child(download_paragraph)

        container
      end
    end

  end
end
