# frozen_string_literal: true

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

      private

      def absolute_image_urls(markdown_text)
        return markdown_text unless markdown_text.present?

        markdown_text.gsub(MARKDOWN_SIMPLE_IMAGE) do
          if $~[:image]
            url = $~[:url]
            url = "#{uploads_prefix}#{url}" if url.start_with?('/uploads')
            url = "/#{url}" unless url.start_with?('/')

            "![#{$~[:title]}](#{Gitlab.config.gitlab.url}#{url})"
          else
            $~[0]
          end
        end
      end

      def uploads_prefix
        project&.full_path || ''
      end

      def project
        return unless object.respond_to?(:project)

        object.project
      end
    end
  end
end
