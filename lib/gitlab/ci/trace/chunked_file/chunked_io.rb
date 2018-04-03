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
          # extend ChunkedFile::Concerns::Opener
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

          def initialize(job_id, size = nil, mode = 'rb', &block)
            raise NotImplementedError, "Mode 'w' is not supported" if mode.include?('w')

            @size = size || calculate_size(job_id)
            @tell = 0
            @job_id = job_id
            @mode = mode

            if block_given?
              begin
                yield self
              ensure
                self.close
              end
            end
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

          def read(length = nil, outbuf = nil)
            out = ""

            until eof? || (length && out.bytesize >= length)
              data = get_chunk
              break if data.empty?

              out << data
              @tell += data.bytesize
            end

            out = out.byteslice(0, length) if length && out.bytesize > length

            out
          end

          def readline
            out = ""

            until eof?
              data = get_chunk
              break if data.empty?

              new_line_pos = byte_position(data, "\n")

              if new_line_pos.nil?
                out << data
                @tell += data.bytesize
              else
                out << data.byteslice(0..new_line_pos)
                @tell += new_line_pos + 1
                break
              end
            end

            out
          end

          def write(data)
            raise ArgumentError, 'Could not write empty data' unless data.present?

            if mode.include?('w')
              raise NotImplementedError, "Overwrite is not supported"
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
            chunks_count > 0
          end

          def delete
            chunk_store.delete_all
          end

          private

          def in_range?
            @chunk_range&.include?(tell)
          end

          def get_chunk
            return '' if size <= 0 || eof?

            unless in_range?
              chunk_store.open(job_id, chunk_index, params_for_store) do |store|
                @chunk = store.get

                raise ReadError, 'Could not get a chunk' unless chunk && chunk.present?

                @chunk_range = (chunk_start...(chunk_start + chunk.bytesize))
              end
            end

            @chunk.byteslice(chunk_offset, buffer_size)
          end

          def write_as_append(data)
            @tell = size

            data_size = data.bytesize
            new_tell = tell + data_size
            data_offset = 0

            until tell == new_tell
              writable_size = buffer_size - chunk_offset
              writable_data = data.byteslice(data_offset, writable_size)
              written_size = write_chunk(writable_data)

              data_offset += written_size
              @tell += written_size
              @size = [tell, size].max
            end

            data_size
          end

          def write_chunk(data)
            written_size = 0

            chunk_store.open(job_id, chunk_index, params_for_store) do |store|
              with_callbacks(:write_chunk, store) do
                written_size = if store.size > 0 # # rubocop:disable ZeroLengthPredicate
                                 store.append!(data)
                               else
                                 store.write!(data)
                               end

                raise WriteError, 'Written size mismatch' unless data.bytesize == written_size
              end
            end

            written_size
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
            (size / buffer_size.to_f).ceil
          end

          def last_chunk?
            ((size / buffer_size) * buffer_size..size).include?(tell)
          end

          def chunk_store
            raise NotImplementedError
          end

          def buffer_size
            raise NotImplementedError
          end

          def calculate_size(job_id)
            chunk_store.chunks_size(job_id)
          end

          def byte_position(data, pattern_byte)
            index_as_string = data.index(pattern_byte)
            return nil unless index_as_string

            if data.getbyte(index_as_string) == pattern_byte.getbyte(0)
              index_as_string
            else
              data2 = data.byteslice(index_as_string, 100)
              additional_pos = 0
              data2.each_byte do |b|
                break if b == pattern_byte.getbyte(0)

                additional_pos += 1
              end

              index_as_string + additional_pos
            end
          end
        end
      end
    end
  end
end
