# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module Markdown
      class Attachment
        # Bitbucket Cloud writes pasted/uploaded images using these two fixed hosts. There is no
        # Bitbucket API/contract guaranteeing them, so if Bitbucket changes its infrastructure this
        # list must be updated. Drift cannot be detected automatically; re-check the sources below.
        #
        # - https://bitbucket.org/repo/{repohash}/... : what Bitbucket writes into markdown for
        #   pasted/uploaded images.
        #   Source: https://support.atlassian.com/bitbucket-cloud/kb/issue-tracker-images-not-loading/
        # - https://bbuseruploads.s3.amazonaws.com/... : where Bitbucket Downloads URLs redirect as
        #   pre-signed S3 URLs.
        #   Source: https://jira.atlassian.com/browse/BCLOUD-12613
        BITBUCKET_MEDIA_HOSTS = %w[
          https://bitbucket.org/repo/
          https://bbuseruploads.s3.amazonaws.com/
        ].freeze

        class << self
          # markdown_node - CommonMarker::Node
          def from_markdown(markdown_node)
            case markdown_node.type
            when :html, :inline_html
              from_inline_html(markdown_node)
            when :image
              from_markdown_image(markdown_node)
            end
          end

          private

          def from_markdown_image(markdown_node)
            url = markdown_node.url

            return unless bitbucket_url?(url)

            new(markdown_node.to_plaintext.strip, url)
          end

          def from_inline_html(markdown_node)
            img = Nokogiri::HTML.parse(markdown_node.string_content).xpath('//img')[0]

            return if img.nil? || img[:src].blank?
            return unless bitbucket_url?(img[:src])

            new(img[:alt], img[:src])
          end

          def bitbucket_url?(url)
            return false unless url

            url.start_with?(*BITBUCKET_MEDIA_HOSTS)
          end
        end

        attr_reader :name, :url

        def initialize(name, url)
          @name = name
          @url = url
        end

        def inspect
          "<#{self.class.name}: { name: #{name}, url: #{url} }>"
        end
      end
    end
  end
end
