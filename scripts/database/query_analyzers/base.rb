# frozen_string_literal: true

require 'json'
require 'zlib'

class Database
  class QueryAnalyzers
    class Base
      attr_accessor :output
      attr_reader :config

      def initialize(config)
        @output = {}
        @config = config
      end

      def filename
        self.class
      end

      def analyze(query); end

      def save!
        Zlib::GzipWriter.open(output_path(filename)) do |file|
          JSON.dump(output, file)
        end
      end

      private

      def output_path(filename)
        File.join(
          File.dirname(ENV['RSPEC_AUTO_EXPLAIN_LOG_PATH']),
          "#{filename}.gz"
        )
      end
    end
  end
end
