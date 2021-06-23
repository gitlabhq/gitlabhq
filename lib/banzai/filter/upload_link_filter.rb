# frozen_string_literal: true

require 'uri'

module Banzai
  module Filter
    # HTML filter that "fixes" links to uploads.
    #
    # Context options:
    #   :group
    #   :only_path
    #   :project
    #   :system_note
    class UploadLinkFilter < BaseRelativeLinkFilter
      def call
        return doc if context[:system_note]

        # We exclude processed upload links from the linkable attributes to
        # prevent further modifications by RepositoryLinkFilter
        linkable_attributes.reject! do |attr|
          process_link_to_upload_attr(attr)
        end

        doc
      end

      protected

      def process_link_to_upload_attr(html_attr)
        return unless html_attr.value.start_with?('/uploads/')

        path_parts = [unescape_and_scrub_uri(html_attr.value)]

        if project
          path_parts.unshift(relative_url_root, project.full_path)
        elsif group
          path_parts.unshift(relative_url_root, 'groups', group.full_path, '-')
        else
          path_parts.unshift(relative_url_root)
        end

        begin
          path = Addressable::URI.escape(File.join(*path_parts))
        rescue Addressable::URI::InvalidURIError
          return
        end

        path =
          if context[:only_path]
            path
          else
            Addressable::URI.join(Gitlab.config.gitlab.base_url, path).to_s
          end

        replace_html_attr_value(html_attr, path)

        if html_attr.name == 'href'
          html_attr.parent.set_attribute('data-link', 'true')
        end

        html_attr.parent.add_class('gfm')
      end

      def replace_html_attr_value(html_attr, path)
        if path != html_attr.value
          preserve_original_link(html_attr, html_attr.parent)
        end

        html_attr.value = path
      end

      def preserve_original_link(html_attr, node)
        return if html_attr.blank?
        return if node.value?('data-canonical-src')

        node.set_attribute('data-canonical-src', html_attr.value)
      end

      def group
        context[:group]
      end
    end
  end
end
