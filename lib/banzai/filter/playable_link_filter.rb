# frozen_string_literal: true

module Banzai
  module Filter
    # Find every image that isn't already wrapped in an `a` tag, and that has
    # a `src` attribute ending with an audio or video extension, add a new audio or video node and
    # a "Download" link in the case the media cannot be played.
    class PlayableLinkFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck

      def call
        doc.xpath('descendant-or-self::img[not(ancestor::a)]').each do |el|
          el.replace(media_node(doc, el)) if has_allowed_media?(el)
        end

        doc
      end

      private

      def media_type
        raise NotImplementedError
      end

      def safe_media_ext
        raise NotImplementedError
      end

      def extra_element_attrs(element)
        {}
      end

      def has_allowed_media?(element)
        src = element.attr('data-canonical-src').presence || element.attr('src')

        return unless src.present?

        src_ext = File.extname(src).sub('.', '').downcase
        safe_media_ext.include?(src_ext)
      end

      def media_element(doc, element)
        media_element_attrs = {
          src: element['src'],
          controls: true,
          'data-setup': '{}',
          'data-title': element['title'] || element['alt']
        }.merge!(extra_element_attrs(element))

        if element['data-canonical-src']
          media_element_attrs['data-canonical-src'] = element['data-canonical-src']
        end

        doc.document.create_element(media_type, media_element_attrs)
      end

      def download_link(doc, element)
        link_content = element['title'] || element['alt']

        link_element_attrs = {
          class: 'gl-text-sm gl-text-subtle gl-mb-1',
          href: element['src'],
          target: '_blank',
          rel: 'noopener noreferrer',
          title: "Download '#{link_content}'"
        }

        # make sure the original non-proxied src carries over
        if element['data-canonical-src']
          link_element_attrs['data-canonical-src'] = element['data-canonical-src']
        end

        doc.document.create_element('a', link_content, link_element_attrs)
      end

      def media_node(doc, element)
        container_element_attrs = { class: "media-container #{media_type}-container" }

        doc.document.create_element('span', container_element_attrs).tap do |container|
          container.add_child(download_link(doc, element))
          container.add_child(media_element(doc, element))
        end
      end
    end
  end
end
