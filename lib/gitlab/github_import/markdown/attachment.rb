# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Markdown
      class Attachment
        MEDIA_TYPES = %w[gif jpeg jpg mov mp4 png svg webm].freeze
        DOC_TYPES = %w[
          csv docx fodg fodp fods fodt gz log md odf odg odp ods
          odt pdf pptx tgz txt xls xlsx zip
        ].freeze

        class << self
          # markdown_node - CommonMarker::Node
          def from_markdown(markdown_node, web_endpoint)
            case markdown_node.type
            when :html, :inline_html
              from_inline_html(markdown_node, web_endpoint)
            when :image
              from_markdown_image(markdown_node, web_endpoint)
            when :link
              from_markdown_link(markdown_node, web_endpoint)
            when :text, :paragraph
              from_markdown_text(markdown_node, web_endpoint)
            end
          end

          private

          # this checks for any attachment links that appear as plain text without
          # a filetype suffix e.g. "https://github.com/user-attachments/assets/75334fd4"
          # each markdown_node will only ever have a single url as embedded media on
          # GitHub is always on its own line
          def from_markdown_text(markdown_node, web_endpoint)
            text = markdown_node.to_plaintext.strip

            url = URI.extract(text, %w[http https]).first
            return if url.nil?

            return unless github_url?(url, web_endpoint, media: true)
            return unless whitelisted_type?(url, web_endpoint, media: true)

            # we don't have the :alt or :name so we use a default name
            new("media_attachment", url, web_endpoint)
          end

          def from_markdown_image(markdown_node, web_endpoint)
            url = markdown_node.url

            return unless url
            return unless github_url?(url, web_endpoint, media: true)
            return unless whitelisted_type?(url, web_endpoint, media: true)

            new(markdown_node.to_plaintext.strip, url, web_endpoint)
          end

          def from_markdown_link(markdown_node, web_endpoint)
            url = markdown_node.url

            return unless url
            return unless github_url?(url, web_endpoint, docs: true)
            return unless whitelisted_type?(url, web_endpoint, docs: true)

            new(markdown_node.to_plaintext.strip, url, web_endpoint)
          end

          def from_inline_html(markdown_node, web_endpoint)
            img = Nokogiri::HTML.parse(markdown_node.string_content).xpath('//img')[0]

            return if img.nil? || img[:src].blank?
            return unless github_url?(img[:src], web_endpoint, media: true)
            return unless whitelisted_type?(img[:src], web_endpoint, media: true)

            new(img[:alt], img[:src], web_endpoint)
          end

          def github_url?(url, web_endpoint, docs: false, media: false)
            if media
              url.start_with?(web_endpoint,
                ::Gitlab::GithubImport::MarkdownText::GITHUB_MEDIA_CDN
              )
            elsif docs
              url.start_with?(web_endpoint)
            end
          end

          def whitelisted_type?(url, web_endpoint, docs: false, media: false)
            if media
              # We do not know the file extension type from the /assets markdown
              return true if url.start_with?(web_endpoint)

              MEDIA_TYPES.any? { |type| url.end_with?(type) }
            elsif docs
              DOC_TYPES.any? { |type| url.end_with?(type) }
            end
          end
        end

        attr_reader :name, :url, :web_endpoint

        def initialize(name, url, web_endpoint)
          @name = name
          @url = url
          @web_endpoint = web_endpoint
        end

        def part_of_project_blob?(import_source)
          url.start_with?(
            "#{web_endpoint}/#{import_source}/blob"
          )
        end

        def doc_belongs_to_project?(import_source)
          url.start_with?(
            "#{web_endpoint}/#{import_source}/files"
          )
        end

        def media?(import_source)
          url.start_with?(
            "#{web_endpoint}/#{import_source}/assets",
            ::Gitlab::GithubImport::MarkdownText::GITHUB_MEDIA_CDN
          )
        end

        def user_attachment?
          url.start_with?("#{web_endpoint}/user-attachments/")
        end

        def inspect
          "<#{self.class.name}: { name: #{name}, url: #{url}, web_endpoint: #{web_endpoint} }>"
        end
      end
    end
  end
end
