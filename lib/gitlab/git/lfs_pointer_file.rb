module Gitlab
  module Git
    class LfsPointerFile
      def initialize(data)
        @data = data
      end

      def pointer
        @pointer ||= <<~FILE
          version https://git-lfs.github.com/spec/v1
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
