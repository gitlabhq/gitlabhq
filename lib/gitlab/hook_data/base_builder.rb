# frozen_string_literal: true

module Gitlab
  module HookData
    class BaseBuilder
      attr_accessor :object

      MARKDOWN_SIMPLE_IMAGE =
        "#{::Gitlab::Regex.markdown_code_or_html_blocks_untrusted}" \
        '|' \
        '(?P<image>' \
        '!' \
        '\[(?P<title>[^\n]*?)\]' \
        '\((?P<url>(?P<https>(https?://|//)?)[^\n]+?)\)' \
        ')'.freeze

      def initialize(object)
        @object = object
      end

      private

      def event_data(event)
        event_name =  "#{object.class.name.downcase}_#{event}"

        { event_name: event_name }
      end

      def timestamps_data
        {
          created_at: object.created_at&.xmlschema,
          updated_at: object.updated_at&.xmlschema
        }
      end

      def absolute_image_urls(markdown_text)
        return markdown_text unless markdown_text.present?

        regex = Gitlab::UntrustedRegexp.new(MARKDOWN_SIMPLE_IMAGE, multiline: false)
        return markdown_text unless regex.match?(markdown_text)

        regex.replace_gsub(markdown_text) do |match|
          if match[:image] && !match[:https]
            url = match[:url]
            url = File.join(uploads_prefix, url) if url.start_with?('/uploads', 'uploads')
            url = "/#{url}" unless url.start_with?('/')

            "![#{match[:title]}](#{Gitlab.config.gitlab.url}#{url})"
          else
            match.to_s
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
