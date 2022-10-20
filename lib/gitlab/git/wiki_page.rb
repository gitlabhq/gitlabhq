# frozen_string_literal: true

module Gitlab
  module Git
    class WikiPage
      attr_reader :url_path, :title, :format, :path, :version, :raw_data, :name, :historical, :formatted_data

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

      def raw_data=(data)
        @raw_data = data
        @text_data = @raw_data && Gitlab::EncodingHelper.encode!(@raw_data.dup)
      end
    end
  end
end
