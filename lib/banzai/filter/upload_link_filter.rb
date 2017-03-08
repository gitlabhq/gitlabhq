require 'uri'

module Banzai
  module Filter
    # HTML filter that "fixes" relative upload links to files.
    # Context options:
    #   :project (required) - Current project
    #
    class UploadLinkFilter < HTML::Pipeline::Filter
      def call
        return doc unless project

        doc.xpath('descendant-or-self::a[starts-with(@href, "/uploads/")]').each do |el|
          process_link_attr el.attribute('href')
        end

        doc.xpath('descendant-or-self::img[starts-with(@src, "/uploads/")]').each do |el|
          process_link_attr el.attribute('src')
        end

        doc
      end

      protected

      def process_link_attr(html_attr)
        html_attr.value = build_url(html_attr.value).to_s
      end

      def build_url(uri)
        if Gitlab::Geo.secondary?
          File.join(Gitlab::Geo.primary_node.url, context[:project].path_with_namespace, uri)
        else
          File.join(Gitlab.config.gitlab.url, context[:project].path_with_namespace, uri)
        end
      end

      def project
        context[:project]
      end

      # Ensure that a :project key exists in context
      #
      # Note that while the key might exist, its value could be nil!
      def validate
        needs :project
      end
    end
  end
end
