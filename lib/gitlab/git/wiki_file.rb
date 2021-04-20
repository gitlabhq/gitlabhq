# frozen_string_literal: true

module Gitlab
  module Git
    class WikiFile
      attr_reader :mime_type, :raw_data, :name, :path

      def initialize(blob)
        @mime_type = blob.mime_type
        @raw_data = blob.data
        @name = File.basename(blob.name)
        @path = blob.path
      end
    end
  end
end
