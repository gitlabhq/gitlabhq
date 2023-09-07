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
          def from_markdown(markdown_node)
            case markdown_node.type
            when :html, :inline_html
              from_inline_html(markdown_node)
            when :image
              from_markdown_image(markdown_node)
            when :link
              from_markdown_link(markdown_node)
            end
          end

          private

          def from_markdown_image(markdown_node)
            url = markdown_node.url

            return unless url
            return unless github_url?(url, media: true)
            return unless whitelisted_type?(url, media: true)

            new(markdown_node.to_plaintext.strip, url)
          end

          def from_markdown_link(markdown_node)
            url = markdown_node.url

            return unless url
            return unless github_url?(url, docs: true)
            return unless whitelisted_type?(url, docs: true)

            new(markdown_node.to_plaintext.strip, url)
          end

          def from_inline_html(markdown_node)
            img = Nokogiri::HTML.parse(markdown_node.string_content).xpath('//img')[0]

            return if img.nil? || img[:src].blank?
            return unless github_url?(img[:src], media: true)
            return unless whitelisted_type?(img[:src], media: true)

            new(img[:alt], img[:src])
          end

          def github_url?(url, docs: false, media: false)
            if media
              url.start_with?(::Gitlab::GithubImport::MarkdownText.github_url,
                ::Gitlab::GithubImport::MarkdownText::GITHUB_MEDIA_CDN)
            elsif docs
              url.start_with?(::Gitlab::GithubImport::MarkdownText.github_url)
            end
          end

          def whitelisted_type?(url, docs: false, media: false)
            if media
              # We do not know the file extension type from the /assets markdown
              return true if url.start_with?(::Gitlab::GithubImport::MarkdownText.github_url)

              MEDIA_TYPES.any? { |type| url.end_with?(type) }
            elsif docs
              DOC_TYPES.any? { |type| url.end_with?(type) }
            end
          end
        end

        attr_reader :name, :url

        def initialize(name, url)
          @name = name
          @url = url
        end

        def part_of_project_blob?(import_source)
          url.start_with?(
            "#{::Gitlab::GithubImport::MarkdownText.github_url}/#{import_source}/blob"
          )
        end

        def doc_belongs_to_project?(import_source)
          url.start_with?(
            "#{::Gitlab::GithubImport::MarkdownText.github_url}/#{import_source}/files"
          )
        end

        def media?(import_source)
          url.start_with?(
            "#{::Gitlab::GithubImport::MarkdownText.github_url}/#{import_source}/assets",
            ::Gitlab::GithubImport::MarkdownText::GITHUB_MEDIA_CDN
          )
        end

        def inspect
          "<#{self.class.name}: { name: #{name}, url: #{url} }>"
        end
      end
    end
  end
end
