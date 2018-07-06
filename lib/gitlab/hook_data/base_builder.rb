module Gitlab
  module HookData
    class BaseBuilder
      attr_accessor :object

      MARKDOWN_SIMPLE_IMAGE = %r{
          #{::Gitlab::Regex.markdown_code_or_html_blocks}
        |
          (?<image>
            !
            \[(?<title>[^\n]*?)\]
            \((?<url>(?!(https?://|//))[^\n]+?)\)
          )
      }mx.freeze

      def initialize(object)
        @object = object
      end

      def self.absolute_image_urls(markdown_text)
        return markdown_text unless markdown_text.present?

        markdown_text.gsub(MARKDOWN_SIMPLE_IMAGE) do
          if $~[:image]
            "![#{$~[:title]}](#{Gitlab.config.gitlab.url}/#{$~[:url]})"
          else
            $~[0]
          end
        end
      end

      private

      def absolute_image_urls(markdown_text)
        self.class.absolute_image_urls(markdown_text)
      end
    end
  end
end
