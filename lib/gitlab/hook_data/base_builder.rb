module Gitlab
  module HookData
    class BaseBuilder
      attr_accessor :object

      def initialize(object)
        @object = object
      end

      private

      def absolute_image_urls(markdown_text)
        return markdown_text unless markdown_text.present?

        markdown_text.gsub(/!\[(.*?)\]\((.*?)\)/,
                           "![\\1](#{Settings.gitlab.url}\\2)")
      end
    end
  end
end
