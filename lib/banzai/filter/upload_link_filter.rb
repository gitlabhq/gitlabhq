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
        base_path = Gitlab.config.gitlab.url
        model_path = if group
                       File.join('groups', group.full_path, '-')
                     else
                       project.full_path
                     end

        File.join(base_path, model_path, uri)
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
