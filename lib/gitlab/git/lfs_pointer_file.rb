# frozen_string_literal: true

module Gitlab
  module Git
    class LfsPointerFile
      VERSION = "https://git-lfs.github.com/spec/v1"
      VERSION_LINE = "version #{VERSION}"

      def initialize(data)
        @data = data
      end

      def pointer
        @pointer ||= <<~FILE
          #{VERSION_LINE}
          oid sha256:#{sha256}
          size #{size}
        FILE
      end

      def size
        @size ||= @data.bytesize
      end

      def sha256
        @sha256 ||= Digest::SHA256.hexdigest(@data)
      end

      def inspect
        "#<#{self.class}:#{object_id} @size=#{size}, @sha256=#{sha256.inspect}>"
      end
    end
  end
end
