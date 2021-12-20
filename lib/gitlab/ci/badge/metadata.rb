# frozen_string_literal: true

module Gitlab::Ci
  module Badge
    ##
    # Abstract class for badge metadata
    #
    class Metadata
      include Gitlab::Routing
      include ActionView::Helpers::AssetTagHelper

      def initialize(badge)
        @badge = badge
      end

      def to_html
        ApplicationController.helpers.link_to(image_tag(image_url, alt: title), link_url)
      end

      def to_markdown
        "[![#{title}](#{image_url})](#{link_url})"
      end

      def to_asciidoc
        "image:#{image_url}[link=\"#{link_url}\",title=\"#{title}\"]"
      end

      def title
        raise NotImplementedError
      end

      def image_url
        raise NotImplementedError
      end

      def link_url
        raise NotImplementedError
      end
    end
  end
end
