# frozen_string_literal: true

module Gitlab
  module Sherlock
    class Location
      attr_reader :path, :line

      SHERLOCK_DIR = File.dirname(__FILE__)

      # Creates a new Location from a `Thread::Backtrace::Location`.
      def self.from_ruby_location(location)
        new(location.path, location.lineno)
      end

      # path - The full path of the frame as a String.
      # line - The line number of the frame as a Fixnum.
      def initialize(path, line)
        @path = path
        @line = line
      end

      # Returns true if the current frame originated from the application.
      def application?
        @path.start_with?(Rails.root.to_s) && !path.start_with?(SHERLOCK_DIR)
      end
    end
  end
end
