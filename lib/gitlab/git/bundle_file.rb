# frozen_string_literal: true

module Gitlab
  module Git
    class BundleFile
      # All git bundle files start with one of these strings
      #
      # https://github.com/git/git/blob/v2.50.1/bundle.c#L24
      MAGIC = "# v2 git bundle\n"
      MAGIC_V3 = "# v3 git bundle\n"

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

        raise InvalidBundleError, 'Invalid bundle file' unless data == MAGIC || data == MAGIC_V3
      end
    end
  end
end
