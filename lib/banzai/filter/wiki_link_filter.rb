require 'uri'

module Banzai
  module Filter
    # HTML filter that "fixes" relative links to files in a repository.
    #
    # Context options:
    #   :project_wiki
    class WikiLinkFilter < HTML::Pipeline::Filter

      def call
        return doc unless project_wiki?

        doc.search('a:not(.gfm)').each do |el|
          process_link_attr el.attribute('href')
        end

        doc
      end

      protected

      def project_wiki?
        !context[:project_wiki].nil?
      end

      def process_link_attr(html_attr)
        return if html_attr.blank? || file_reference?(html_attr)

        uri = URI(html_attr.value)
        if uri.relative? && uri.path.present?
          html_attr.value = rebuild_wiki_uri(uri).to_s
        end
      rescue URI::Error
        # noop
      end

      def rebuild_wiki_uri(uri)
        uri.path = ::File.join(project_wiki_base_path, uri.path)
        uri
      end

      def file_reference?(html_attr)
        !File.extname(html_attr.value).blank?
      end

      def project_wiki
        context[:project_wiki]
      end

      def project_wiki_base_path
        project_wiki && project_wiki.wiki_base_path
      end
    end
  end
end
