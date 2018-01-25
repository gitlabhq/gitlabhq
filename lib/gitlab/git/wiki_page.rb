module Gitlab
  module Git
    class WikiPage
      attr_reader :url_path, :title, :format, :path, :version, :raw_data, :name, :text_data, :historical, :formatted_data

      # This class is meant to be serializable so that it can be constructed
      # by Gitaly and sent over the network to GitLab.
      #
      # Because Gollum::Page is not serializable we must get all the data from
      # 'gollum_page' during initialization, and NOT store it in an instance
      # variable.
      #
      # Note that 'version' is a WikiPageVersion instance which it itself
      # serializable. That means it's OK to store 'version' in an instance
      # variable.
      def initialize(gollum_page, version)
        @url_path = gollum_page.url_path
        @title = gollum_page.title
        @format = gollum_page.format
        @path = gollum_page.path
        @raw_data = gollum_page.raw_data
        @name = gollum_page.name
        @historical = gollum_page.historical?
        @formatted_data = gollum_page.formatted_data if gollum_page.is_a?(Gollum::Page)

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
