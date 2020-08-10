# frozen_string_literal: true

require 'zlib'

module Gitlab
  module ImportExport
    class DecompressedArchiveSizeValidator
      include Gitlab::Utils::StrongMemoize

      DEFAULT_MAX_BYTES = 10.gigabytes.freeze
      CHUNK_SIZE = 4096.freeze

      attr_reader :error

      def initialize(archive_path:, max_bytes: self.class.max_bytes)
        @archive_path = archive_path
        @max_bytes = max_bytes
        @bytes_read = 0
        @total_reads = 0
        @denominator = 5
        @error = nil
      end

      def valid?
        strong_memoize(:valid) do
          validate
        end
      end

      def self.max_bytes
        DEFAULT_MAX_BYTES
      end

      def archive_file
        @archive_file ||= File.open(@archive_path)
      end

      private

      def validate
        until archive_file.eof?
          compressed_chunk = archive_file.read(CHUNK_SIZE)

          inflate_stream.inflate(compressed_chunk) do |chunk|
            @bytes_read += chunk.size
            @total_reads += 1
          end

          # Start garbage collection every 5 reads in order
          # to prevent memory bloat during archive decompression
          GC.start if gc_start?

          if @bytes_read > @max_bytes
            @error = error_message

            return false
          end
        end

        true
      rescue => e
        @error = error_message

        Gitlab::ErrorTracking.track_exception(e)

        Gitlab::Import::Logger.info(
          message: @error,
          error: e.message
        )

        false
      ensure
        inflate_stream.close
        archive_file.close
      end

      def inflate_stream
        @inflate_stream ||= Zlib::Inflate.new(Zlib::MAX_WBITS + 32)
      end

      def gc_start?
        @total_reads % @denominator == 0
      end

      def error_message
        _('Decompressed archive size validation failed.')
      end
    end
  end
end
