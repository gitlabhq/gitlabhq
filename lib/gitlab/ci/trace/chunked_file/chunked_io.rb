##
# ChunkedIO Engine
#
# Choose a chunk_store with your purpose
# This class is designed that it's compatible with IO class (https://ruby-doc.org/core-2.3.1/IO.html)
module Gitlab
  module Ci
    class Trace
      module ChunkedFile
        class ChunkedIO
          class << self
            def open(*args)
              stream = self.new(*args)

              yield stream
            ensure
              stream&.close
            end
          end

          WriteError = Class.new(StandardError)
          FailedToGetChunkError = Class.new(StandardError)

          attr_reader :size
          attr_reader :tell
          attr_reader :chunk, :chunk_range
          attr_reader :write_lock_uuid
          attr_reader :job_id

          alias_method :pos, :tell

          def initialize(job_id, size, mode)
            @size = size
            @tell = 0
            @job_id = job_id

            if /(w|a)/ =~ mode
              @write_lock_uuid = Gitlab::ExclusiveLease.new(write_lock_key, timeout: 1.hour.to_i).try_obtain

              raise WriteError, 'Already opened by another process' unless write_lock_uuid

              seek(0, IO::SEEK_END) if /a/ =~ mode
            end
          end

          def close
            Gitlab::ExclusiveLease.cancel(write_lock_key, write_lock_uuid) if write_lock_uuid
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

            raise 'new position is outside of file' if new_pos < 0 || new_pos > size

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

          def read(length = nil)
            out = ""

            until eof? || (length && out.length >= length)
              data = get_chunk
              break if data.empty?

              out << data
              @tell += data.bytesize
            end

            out = out[0, length] if length && out.length > length

            out
          end

          def readline
            out = ""

            until eof?
              data = get_chunk
              new_line = data.index("\n")

              if !new_line.nil?
                out << data[0..new_line]
                @tell += new_line + 1
                break
              else
                out << data
                @tell += data.bytesize
              end
            end

            out
          end

          def write(data, &block)
            raise WriteError, 'Could not write without lock' unless write_lock_uuid
            raise WriteError, 'Could not write empty data' unless data.present?

            _data = data.dup
            prev_tell = tell

            until _data.empty?
              writable_space = buffer_size - chunk_offset
              writing_size = [writable_space, _data.length].min
              written_size = write_chunk!(_data.slice!(0...writing_size), &block)

              @tell += written_size
              @size = [tell, size].max
            end

            tell - prev_tell
          end

          def truncate(offset, &block)
            raise WriteError, 'Could not write without lock' unless write_lock_uuid
            raise WriteError, 'Offset is out of bound' if offset > size || offset < 0

            @tell = size - 1

            until size == offset
              truncatable_space = size - chunk_start
              _chunk_offset = (offset <= chunk_start) ? 0 : offset % buffer_size
              removed_size = truncate_chunk!(_chunk_offset, &block)

              @tell -= removed_size
              @size -= removed_size
            end

            @tell = [tell, 0].max
            @size = [size, 0].max
          end

          def flush
            # no-op
          end

          def present?
            true
          end

          private

          def in_range?
            @chunk_range&.include?(tell)
          end

          def get_chunk
            unless in_range?
              chunk_store.open(job_id, chunk_index, params_for_store) do |store|
                @chunk = store.get

                raise FailedToGetChunkError unless chunk && chunk.length > 0

                @chunk_range = (chunk_start...(chunk_start + chunk.length))
              end
            end

            @chunk[chunk_offset..buffer_size]
          end

          def write_chunk!(data, &block)
            chunk_store.open(job_id, chunk_index, params_for_store) do |store|
              written_size = if buffer_size == data.length
                               store.write!(data)
                             else
                               store.append!(data)
                             end

              raise WriteError, 'Written size mismatch' unless data.length == written_size

              block.call(store) if block_given?

              written_size
            end
          end

          def truncate_chunk!(offset, &block)
            chunk_store.open(job_id, chunk_index, params_for_store) do |store|
              removed_size = store.size - offset
              store.truncate!(offset)

              block.call(store) if block_given?

              removed_size
            end
          end

          def params_for_store(c_index = chunk_index)
            {
              buffer_size: buffer_size,
              chunk_start: c_index * buffer_size,
              chunk_index: c_index
            }
          end

          def chunk_offset
            tell % buffer_size
          end

          def chunk_start
            chunk_index * buffer_size
          end

          def chunk_end
            [chunk_start + buffer_size, size].min
          end

          def chunk_index
            (tell / buffer_size)
          end

          def chunks_count
            (size / buffer_size) + (has_extra? ? 1 : 0)
          end

          def has_extra?
            (size % buffer_size) > 0
          end

          def last_chunk?
            chunks_count == 0 || chunk_index == (chunks_count - 1) || chunk_index == chunks_count
          end

          def write_lock_key
            "live_trace:operation:write:#{job_id}"
          end

          def chunk_store
            raise NotImplementedError
          end

          def buffer_size
            raise NotImplementedError
          end
        end
      end
    end
  end
end
