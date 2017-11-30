module Gitlab
  module Git
    class WikiFile
      attr_reader :mime_type, :raw_data, :name, :path

      # This class is meant to be serializable so that it can be constructed
      # by Gitaly and sent over the network to GitLab.
      #
      # Because Gollum::File is not serializable we must get all the data from
      # 'gollum_file' during initialization, and NOT store it in an instance
      # variable.
      def initialize(gollum_file)
        @mime_type = gollum_file.mime_type
        @raw_data = gollum_file.raw_data
        @name = gollum_file.name
        @path = gollum_file.path
      end
    end
  end
end
