##
# This class is designed as it's compatible with IO class (https://ruby-doc.org/core-2.3.1/IO.html)
module Gitlab
  module Ci
    class Trace
      module ChunkedFile
        class ChunkedIO
          class << self
            def open(job_id, size, mode)
              stream = self.new(job_id, size, mode)

              yield stream
            ensure
              stream.close
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

            data = data.dup

            chunk_index_start = chunk_index
            chunk_index_end = (tell + data.length) / BUFFER_SIZE
            prev_tell = tell

            (chunk_index_start..chunk_index_end).each do |c_index|
              chunk_store.open(job_id, c_index, params_for_store) do |store|
                writable_space = BUFFER_SIZE - chunk_offset
                writing_size = [writable_space, data.length].min

                if store.size > 0
                  written_size = store.append!(data.slice!(0...writing_size))
                else
                  written_size = store.write!(data.slice!(0...writing_size))
                end

                raise WriteError, 'Written size mismatch' unless writing_size == written_size

                @tell += written_size
                @size = [tell, size].max

                block.call(store, c_index) if block_given?
              end
            end

            tell - prev_tell
          end

          def truncate(offset, &block)
            raise WriteError, 'Could not write without lock' unless write_lock_uuid
            raise WriteError, 'Offset is out of bound' if offset > size || offset < 0

            chunk_index_start = (offset / BUFFER_SIZE)
            chunk_index_end = chunks_count - 1

            (chunk_index_start..chunk_index_end).reverse_each do |c_index|
              chunk_store.open(job_id, c_index, params_for_store) do |store|
                c_index_start = c_index * BUFFER_SIZE

                if offset <= c_index_start
                  store.delete!
                else
                  store.truncate!(offset - c_index_start) if store.size > 0
                end

                block.call(store, c_index) if block_given?
              end
            end

            @tell = @size = offset
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

                raise FailedToGetChunkError unless chunk

                @chunk_range = (chunk_start...(chunk_start + chunk.length))
              end
            end

            @chunk[chunk_offset..BUFFER_SIZE]
          end

          def params_for_store
            {
              buffer_size: BUFFER_SIZE,
              chunk_start: chunk_start
            }
          end

          def chunk_offset
            tell % BUFFER_SIZE
          end

          def chunk_start
            (tell / BUFFER_SIZE) * BUFFER_SIZE
          end

          def chunk_end
            [chunk_start + BUFFER_SIZE, size].min
          end

          def chunk_index
            (tell / BUFFER_SIZE)
          end

          def chunks_count
            (size / BUFFER_SIZE) + 1
          end

          def last_chunk?
            chunk_index == (chunks_count - 1)
          end

          def write_lock_key
            "live_trace:operation:write:#{job_id}"
          end

          def chunk_store
            raise NotImplementedError
          end
        end
      end
    end
  end
end
