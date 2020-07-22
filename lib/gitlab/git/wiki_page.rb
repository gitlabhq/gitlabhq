# frozen_string_literal: true

module Gitlab
  module Git
    class WikiPage
      attr_reader :url_path, :title, :format, :path, :version, :raw_data, :name, :historical, :formatted_data

      # This class abstracts away Gitlab::GitalyClient::WikiPage
      def initialize(gitaly_page, version)
        @url_path = gitaly_page.url_path
        @title = gitaly_page.title
        @format = gitaly_page.format
        @path = gitaly_page.path
        @raw_data = gitaly_page.raw_data
        @name = gitaly_page.name
        @historical = gitaly_page.historical?

        @version = version
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
