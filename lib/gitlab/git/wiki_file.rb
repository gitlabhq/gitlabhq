# frozen_string_literal: true

module Gitlab
  module Git
    class WikiFile
      attr_reader :mime_type, :raw_data, :name, :path

      # This class wraps Gitlab::GitalyClient::WikiFile
      def initialize(gitaly_file)
        @mime_type = gitaly_file.mime_type
        @raw_data = gitaly_file.raw_data
        @name = gitaly_file.name
        @path = gitaly_file.path
      end
    end
  end
end
