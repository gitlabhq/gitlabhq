# frozen_string_literal: true

module Banzai
  module Filter
    # Find every image that isn't already wrapped in an `a` tag, and that has
    # a `src` attribute ending with a video extension, add a new video node and
    # a "Download" link in the case the video cannot be played.
    class VideoLinkFilter < HTML::Pipeline::Filter
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

      def video_node(doc, element)
        container = doc.document.create_element(
          'div',
          class: 'video-container'
        )

        video = doc.document.create_element(
          'video',
          src: element['src'],
          width: '400',
          controls: true,
          'data-setup' => '{}',
          'data-title' => element['title'] || element['alt'])

        link = doc.document.create_element(
          'a',
          element['title'] || element['alt'],
          href: element['src'],
          target: '_blank',
          rel: 'noopener noreferrer',
          title: "Download '#{element['title'] || element['alt']}'")
        download_paragraph = doc.document.create_element('p')
        download_paragraph.children = link

        container.add_child(video)
        container.add_child(download_paragraph)

        container
      end
    end
  end
end
