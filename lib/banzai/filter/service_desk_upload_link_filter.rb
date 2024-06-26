# frozen_string_literal: true

module Banzai
  module Filter
    # HTML filter for service desk emails.
    # Context options:
    #   :replace_upload_links
    class ServiceDeskUploadLinkFilter < BaseRelativeLinkFilter
      prepend Concerns::PipelineTimingCheck

      def call
        return doc unless context[:uploads_as_attachments].present?

        linkable_attributes.reject! do |attr|
          replace_upload_link(attr)
        end

        doc
      end

      protected

      def replace_upload_link(html_attr)
        return unless html_attr.name == 'href'
        return unless html_attr.value.start_with?('/uploads/')

        secret, filename_in_link = html_attr.value.scan(FileUploader::DYNAMIC_PATH_PATTERN).first
        return unless context[:uploads_as_attachments].include?("#{secret}/#{filename_in_link}")

        parent = html_attr.parent
        filename_in_text = parent.text
        final_filename = if filename_in_link != filename_in_text
                           "#{filename_in_text} (#{filename_in_link})"
                         else
                           filename_in_text
                         end

        final_element = Nokogiri::HTML::DocumentFragment.parse("<strong>#{final_filename}</strong>")
        parent.replace(final_element)
      end
    end
  end
end
