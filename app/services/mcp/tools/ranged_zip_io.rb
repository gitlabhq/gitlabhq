# frozen_string_literal: true

module Mcp
  module Tools
    # Adapts Gitlab::HttpIO for Zip::File.open_buffer, so a zip's central directory
    # and a single entry are fetched through ranged requests instead of downloading
    # the whole archive. Reads through the adapter are sequential-only: rubyzip dups
    # the IO per entry stream, and the duplicates share the underlying HttpIO.
    class RangedZipIo < SimpleDelegator
      # rubyzip probes for `eof`; HttpIO only implements `eof?`.
      def eof
        __getobj__.eof?
      end

      # Zip::File takes io.path as the archive name and reopens entry streams from
      # that "path"; HttpIO#path must not leak through, or entry reads fail with
      # ENOENT on an empty filename.
      def respond_to?(name, include_private = false)
        return false if name == :path

        super
      end

      # rubyzip's end-of-central-directory scan seeks ~64 KB back from the end and
      # rescues the Errno::EINVAL a File raises when that lands before offset 0;
      # HttpIO raises a bare RuntimeError instead, which escaped the scan and broke
      # every archive smaller than the window.
      def seek(amount, whence = IO::SEEK_SET)
        __getobj__.seek(amount, whence)
      rescue RuntimeError => e
        raise Errno::EINVAL, e.message
      end
    end
  end
end
