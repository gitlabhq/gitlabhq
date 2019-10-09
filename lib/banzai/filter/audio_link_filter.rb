# frozen_string_literal: true

# Generated HTML is transformed back to GFM by app/assets/javascripts/behaviors/markdown/nodes/audio.js
module Banzai
  module Filter
    # Find every image that isn't already wrapped in an `a` tag, and that has
    # a `src` attribute ending with an audio extension, add a new audio node and
    # a "Download" link in the case the audio cannot be played.
    class AudioLinkFilter < HTML::Pipeline::Filter
      def call
        doc.xpath('descendant-or-self::img[not(ancestor::a)]').each do |el|
          el.replace(audio_node(doc, el)) if has_audio_extension?(el)
        end

        doc
      end

      private

      def has_audio_extension?(element)
        src = element.attr('data-canonical-src').presence || element.attr('src')

        return unless src.present?

        src_ext = File.extname(src).sub('.', '').downcase
        Gitlab::FileTypeDetection::SAFE_AUDIO_EXT.include?(src_ext)
      end

      def audio_node(doc, element)
        container = doc.document.create_element(
          'div',
          class: 'audio-container'
        )

        audio = doc.document.create_element(
          'audio',
          src: element['src'],
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

        # make sure the original non-proxied src carries over
        if element['data-canonical-src']
          audio['data-canonical-src'] = element['data-canonical-src']
          link['data-canonical-src']  = element['data-canonical-src']
        end

        download_paragraph = doc.document.create_element('p')
        download_paragraph.children = link

        container.add_child(audio)
        container.add_child(download_paragraph)

        container
      end
    end
  end
end
