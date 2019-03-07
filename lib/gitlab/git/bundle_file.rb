# frozen_string_literal: true

module Gitlab
  module Git
    class BundleFile
      # All git bundle files start with this string
      #
      # https://github.com/git/git/blob/v2.20.1/bundle.c#L15
      MAGIC = "# v2 git bundle\n"

      InvalidBundleError = Class.new(StandardError)

      attr_reader :filename

      def self.check!(filename)
        new(filename).check!
      end

      def initialize(filename)
        @filename = filename
      end

      def check!
        data = File.open(filename, 'r') { |f| f.read(MAGIC.size) }

        raise InvalidBundleError, 'Invalid bundle file' unless data == MAGIC
      end
    end
  end
end
