module Gitlab
  module Sherlock
    class Location
      attr_reader :path, :line

      SHERLOCK_DIR = File.dirname(__FILE__)

      def self.from_ruby_location(location)
        new(location.path, location.lineno)
      end

      def initialize(path, line)
        @path = path
        @line = line
      end

      def application?
        @path.start_with?(Rails.root.to_s) && !path.start_with?(SHERLOCK_DIR)
      end
    end
  end
end
