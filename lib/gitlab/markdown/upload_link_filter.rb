require 'gitlab/markdown'
require 'html/pipeline/filter'
require 'uri'

module Gitlab
  module Markdown
    # HTML filter that "fixes" relative upload links to files.

    class UploadLinkFilter < HTML::Pipeline::Filter
      def call
        doc.search('a').each do |el|
          process_link_attr el.attribute('href')
        end

        doc.search('img').each do |el|
          process_link_attr el.attribute('src')
        end

        doc
      end

      protected

      def process_link_attr(html_attr)
        return if html_attr.blank?

        uri = html_attr.value
        if uri.starts_with?("/uploads/")
          html_attr.value = build_url(uri).to_s
        end
      end

      def build_url(uri)
        File.join(Gitlab.config.gitlab.url, context[:project].path_with_namespace, uri)
      end
    end
  end
end
