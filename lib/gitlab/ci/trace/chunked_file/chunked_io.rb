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
          extend ChunkedFile::Concerns::Opener
          include ChunkedFile::Concerns::Errors
          include ChunkedFile::Concerns::Hooks
          include ChunkedFile::Concerns::Callbacks
          prepend ChunkedFile::Concerns::Permissions

          attr_reader :size
          attr_reader :tell
          attr_reader :chunk, :chunk_range
          attr_reader :job_id
          attr_reader :mode

          alias_method :pos, :tell

          def initialize(job_id, size, mode = 'rb')
            @size = size
            @tell = 0
            @job_id = job_id
            @mode = mode

            raise NotImplementedError, "Mode 'w' is not supported" if mode.include?('w')
          end

          def close
          end

          def binmode
            # no-op
          end

          def binmode?
            true
          end

          def seek(amount, where = IO::SEEK_SET)
            new_pos =
              case where
              when IO::SEEK_END
                size + amount
              when IO::SEEK_SET
                amount
              when IO::SEEK_CUR
                tell + amount
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

          def write(data)
            raise ArgumentError, 'Could not write empty data' unless data.present?

            if mode.include?('w')
              write_as_overwrite(data)
            elsif mode.include?('a')
              write_as_append(data)
            end
          end

          def truncate(offset)
            raise NotImplementedError
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
                @chunk_range = (chunk_start...(chunk_start + chunk.length))
              end
            end

            @chunk[chunk_offset..buffer_size]
          end

          def write_as_overwrite(data)
            raise NotImplementedError, "Overwrite is not supported"
          end

          def write_as_append(data)
            @tell = size

            data_size = data.size
            new_tell = tell + data_size
            data_offset = 0

            until tell == new_tell
              writable_size = buffer_size - chunk_offset
              writable_data = data[data_offset...(data_offset + writable_size)]
              written_size = write_chunk(writable_data)

              data_offset += written_size
              @tell += written_size
              @size = [tell, size].max
            end

            data_size
          end

          def write_chunk(data)
            chunk_store.open(job_id, chunk_index, params_for_store) do |store|
              with_callbacks(:write_chunk, store) do
                written_size = if buffer_size == data.length
                                 store.write!(data)
                               else
                                 store.append!(data)
                               end

                raise WriteError, 'Written size mismatch' unless data.length == written_size

                written_size
              end
            end
          end

          def truncate_chunk(offset)
            chunk_store.open(job_id, chunk_index, params_for_store) do |store|
              with_callbacks(:truncate_chunk, store) do
                removed_size = store.size - offset
                store.truncate!(offset)

                removed_size
              end
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
            (size / buffer_size)
          end

          def first_chunk?
            chunk_index == 0
          end

          def last_chunk?
            chunks_count == 0 || chunk_index == (chunks_count - 1)
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
