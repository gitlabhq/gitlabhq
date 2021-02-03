# frozen_string_literal: true

module Gitlab
  module Ci
    class Trace
      ##
      # Trace::Checksum class is responsible for calculating a CRC32 checksum
      # of an entire build trace using partial build trace chunks stored in a
      # database.
      #
      # CRC32 checksum can be easily calculated by combining partial checksums
      # in a right order.
      #
      # Then we compare CRC32 checksum provided by a GitLab Runner and expect
      # it to be the same as the CRC32 checksum derived from partial chunks.
      #
      class Checksum
        include Gitlab::Utils::StrongMemoize

        attr_reader :build

        def initialize(build)
          @build = build
        end

        def valid?
          return false unless state_crc32.present?

          state_crc32 == chunks_crc32
        end

        def state_crc32
          strong_memoize(:state_crc32) do
            ::Gitlab::Database::Consistency.with_read_consistency do
              build.pending_state&.crc32
            end
          end
        end

        def chunks_crc32
          strong_memoize(:chunks_crc32) do
            trace_chunks.reduce(0) do |crc32, chunk|
              Zlib.crc32_combine(crc32, chunk.crc32, chunk_size(chunk))
            end
          end
        end

        def last_chunk
          strong_memoize(:last_chunk) { trace_chunks.max }
        end

        ##
        # Trace chunks will be persisted in a database if an object store is
        # not configured - in that case we do not want to load entire raw data
        # of all the chunks into memory.
        #
        # We ignore `raw_data` attribute instead, and rely on internal build
        # trace chunk database adapter to handle
        # `ActiveModel::MissingAttributeError` exception.
        #
        # Alternative solution would be separating chunk data from chunk
        # metadata on the database level too.
        #
        def trace_chunks
          strong_memoize(:trace_chunks) do
            ::Ci::BuildTraceChunk.with_read_consistency(build) do
              build.trace_chunks.persisted
                .select(::Ci::BuildTraceChunk.metadata_attributes)
            end
          end
        end

        def state_bytesize
          strong_memoize(:state_bytesize) do
            build.pending_state&.trace_bytesize
          end
        end

        def trace_size
          strong_memoize(:trace_size) do
            trace_chunks.sum { |chunk| chunk_size(chunk) }
          end
        end

        def corrupted?
          return false unless has_bytesize?
          return false if valid?

          state_bytesize.to_i != trace_size.to_i
        end

        def chunks_count
          trace_chunks.to_a.size
        end

        def has_bytesize?
          state_bytesize.present?
        end

        private

        def chunk_size(chunk)
          if chunk == last_chunk
            chunk.size
          else
            ::Ci::BuildTraceChunk::CHUNK_SIZE
          end
        end
      end
    end
  end
end
