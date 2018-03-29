##
# This class is compatible with IO class (https://ruby-doc.org/core-2.3.1/IO.html)
# source: https://gitlab.com/snippets/1685610
module Gitlab
  module Ci
    class Trace
      module ChunkedFile
        class ChunkedIO
          WriteError = Class.new(StandardError)

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

          def path
            nil
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
            raise WriteError, 'Already opened by another process' unless write_lock_uuid

            while data.present?
              empty_space = BUFFER_SIZE - chunk_offset

              chunk_store.open(job_id, chunk_index, params_for_store) do |store|
                data_to_write = ''
                data_to_write += store.get if store.size > 0
                data_to_write += data.slice!(0..empty_space)

                written_size = store.write!(data_to_write)

                raise WriteError, 'Written size mismatch' unless data_to_write.length == written_size

                block.call(store, chunk_index) if block_given?

                @tell += written_size
                @size += written_size
              end
            end
          end

          def truncate(offset)
            raise WriteError, 'Already opened by another process' unless write_lock_uuid

            removal_chunk_index_start = (offset / BUFFER_SIZE)
            removal_chunk_index_end = chunks_count - 1
            removal_chunk_offset = offset % BUFFER_SIZE

            if removal_chunk_offset > 0
              chunk_store.open(job_id, removal_chunk_index_start, params_for_store) do |store|
                store.truncate!(removal_chunk_offset)
              end

              removal_chunk_index_start += 1
            end

            (removal_chunk_index_start..removal_chunk_index_end).each do |removal_chunk_index|
              chunk_store.open(job_id, removal_chunk_index, params_for_store) do |store|
                store.delete!
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

          def delete_chunks!
            truncate(0)
          end

          private

          ##
          # The below methods are not implemented in IO class
          #
          def in_range?
            @chunk_range&.include?(tell)
          end

          def get_chunk
            unless in_range?
              chunk_store.open(job_id, chunk_index, params_for_store) do |store|
                @chunk = store.get
                @chunk_range = (chunk_start...(chunk_start + @chunk.length))
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
        end
      end
    end
  end
end
