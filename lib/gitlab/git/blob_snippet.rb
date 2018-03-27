# Gitaly note: JV: no RPC's here.

module Gitlab
  module Git
    class BlobSnippet
      include Linguist::BlobHelper

      attr_accessor :ref
      attr_accessor :lines
      attr_accessor :filename
      attr_accessor :startline

      def initialize(ref, lines, startline, filename)
        @ref, @lines, @startline, @filename = ref, lines, startline, filename
      end

      def data
        lines&.join("\n")
      end

      def name
        filename
      end

      def size
        data.length
      end

      def mode
        nil
      end
    end
  end
end
