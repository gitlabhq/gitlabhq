# frozen_string_literal: true

module Gitlab
  module Git
    class WikiPage
      attr_reader :url_path, :title, :format, :path, :version, :raw_data, :name, :historical, :formatted_data

      class << self
        # Abstracts away Gitlab::GitalyClient::WikiPage
        def from_gitaly_wiki_page(gitaly_page, version)
          new(
            url_path: gitaly_page.url_path,
            title: gitaly_page.title,
            format: gitaly_page.format,
            path: gitaly_page.path,
            raw_data: gitaly_page.raw_data,
            name: gitaly_page.name,
            historical: gitaly_page.historical?,
            version: version
          )
        end
      end

      def initialize(hash)
        @url_path = hash[:url_path]
        @title = hash[:title]
        @format = hash[:format]
        @path = hash[:path]
        @raw_data = hash[:raw_data]
        @name = hash[:name]
        @historical = hash[:historical]
        @version = hash[:version]
      end

      def historical?
        @historical
      end

      def text_data
        return @text_data if defined?(@text_data)

        @text_data = @raw_data && Gitlab::EncodingHelper.encode!(@raw_data.dup)
      end
    end
  end
end
