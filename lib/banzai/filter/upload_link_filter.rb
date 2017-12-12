require 'uri'

module Banzai
  module Filter
    # HTML filter that "fixes" relative upload links to files.
    # Context options:
    #   :project (required) - Current project
    #
    class UploadLinkFilter < HTML::Pipeline::Filter
      def call
        return doc unless project || group

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
        base_path = if Gitlab::Geo.secondary?
                      Gitlab::Geo.primary_node.url
                    else
                      Gitlab.config.gitlab.url
                    end

        if group
          urls = Gitlab::Routing.url_helpers
          # we need to get last 2 parts of the uri which are secret and filename
          uri_parts = uri.split(File::SEPARATOR)
          file_path = urls.show_group_uploads_path(group, uri_parts[-2], uri_parts[-1])
          File.join(base_path, file_path)
        else
          File.join(base_path, project.full_path, uri)
        end
      end

      def project
        context[:project]
      end

      def group
        context[:group]
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
