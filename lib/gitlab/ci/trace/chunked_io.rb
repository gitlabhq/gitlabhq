# frozen_string_literal: true

##
# This class is compatible with IO class (https://ruby-doc.org/core-2.3.1/IO.html)
# source: https://gitlab.com/snippets/1685610
module Gitlab
  module Ci
    class Trace
      class ChunkedIO
        CHUNK_SIZE = ::Ci::BuildTraceChunk::CHUNK_SIZE

        FailedToGetChunkError = Class.new(StandardError)

        attr_reader :build
        attr_reader :tell, :size
        attr_reader :chunk_data, :chunk_range

        alias_method :pos, :tell

        def initialize(build, &block)
          @build = build
          @chunks_cache = []
          @tell = 0
          @size = calculate_size
          yield self if block
        end

        def close
          # no-op
        end

        def binmode
          # no-op
        end

        def binmode?
          true
        end

        def seek(pos, where = IO::SEEK_SET)
          new_pos =
            case where
            when IO::SEEK_END
              size + pos
            when IO::SEEK_SET
              pos
            when IO::SEEK_CUR
              tell + pos
            else
              -1
            end

          raise ArgumentError, 'new position is outside of file' if new_pos < 0 || new_pos > size

          @tell = new_pos
        end

        def eof?
          tell == size
        end

        def each_line
          until eof?
            line = readline
            break if line.nil?

            yield(line)
          end
        end

        def read(length = nil, outbuf = nil)
          out = []

          length ||= size - tell

          until length <= 0 || eof?
            data = chunk_slice_from_offset
            raise FailedToGetChunkError if data.to_s.empty?

            chunk_bytes = [CHUNK_SIZE - chunk_offset, length].min
            chunk_data_slice = data.byteslice(0, chunk_bytes)

            out << chunk_data_slice
            @tell += chunk_data_slice.bytesize
            length -= chunk_data_slice.bytesize
          end

          out = out.join

          # If outbuf is passed, we put the output into the buffer. This supports IO.copy_stream functionality
          if outbuf
            outbuf.replace(out)
          end

          out
        end

        def readline
          out = []

          until eof?
            data = chunk_slice_from_offset
            raise FailedToGetChunkError if data.to_s.empty?

            new_line = data.index("\n")

            if !new_line.nil?
              raw_data = data[0..new_line]
              out << raw_data
              @tell += raw_data.bytesize
              break
            else
              out << data
              @tell += data.bytesize
            end
          end

          out.join
        end

        def write(data)
          start_pos = tell

          while tell < start_pos + data.bytesize
            # get slice from current offset till the end where it falls into chunk
            chunk_bytes = CHUNK_SIZE - chunk_offset
            data_slice = data.byteslice(tell - start_pos, chunk_bytes)

            # append data to chunk, overwriting from that point
            ensure_chunk.append(data_slice, chunk_offset)

            # move offsets within buffer
            @tell += data_slice.bytesize
            @size = [size, tell].max
          end

          tell - start_pos
        ensure
          invalidate_chunk_cache
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def truncate(offset)
          raise ArgumentError, 'Outside of file' if offset > size || offset < 0
          return if offset == size # Skip the following process as it doesn't affect anything

          @tell = offset
          @size = offset

          # remove all next chunks
          trace_chunks.where('chunk_index > ?', chunk_index).fast_destroy_all

          # truncate current chunk
          current_chunk.truncate(chunk_offset)
        ensure
          invalidate_chunk_cache
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def flush
          # no-op
        end

        def present?
          true
        end

        def destroy!
          trace_chunks.fast_destroy_all
          @tell = @size = 0
        ensure
          invalidate_chunk_cache
        end

        private

        ##
        # The below methods are not implemented in IO class
        #
        def in_range?
          @chunk_range&.include?(tell)
        end

        def chunk_slice_from_offset
          unless in_range?
            current_chunk.tap do |chunk|
              raise FailedToGetChunkError unless chunk

              @chunk_data = chunk.data
              @chunk_range = chunk.range
            end
          end

          @chunk_data.byteslice(chunk_offset, CHUNK_SIZE)
        end

        def chunk_offset
          tell % CHUNK_SIZE
        end

        def chunk_index
          tell / CHUNK_SIZE
        end

        def chunk_start
          chunk_index * CHUNK_SIZE
        end

        def chunk_end
          [chunk_start + CHUNK_SIZE, size].min
        end

        def invalidate_chunk_cache
          @chunks_cache = []
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def current_chunk
          @chunks_cache[chunk_index] ||= trace_chunks.find_by(chunk_index: chunk_index)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def next_chunk
          @chunks_cache[chunk_index] = begin
            ::Ci::BuildTraceChunk
              .safe_find_or_create_by(build: build, chunk_index: chunk_index)
          end
        end

        def ensure_chunk
          current_chunk || next_chunk || current_chunk
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def trace_chunks
          ::Ci::BuildTraceChunk.where(build: build)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        # rubocop: disable CodeReuse/ActiveRecord
        def calculate_size
          trace_chunks.order(chunk_index: :desc).first.try(&:end_offset).to_i
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
