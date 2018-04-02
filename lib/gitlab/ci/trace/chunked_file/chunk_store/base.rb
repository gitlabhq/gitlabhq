module Gitlab
  module Ci
    class Trace
      module ChunkedFile
        module ChunkStore
          class Base
            attr_reader :params

            def initialize(*identifiers, **params)
              @params = params
            end

            def close
              raise NotImplementedError
            end

            def get
              raise NotImplementedError
            end

            def size
              raise NotImplementedError
            end

            # Write data to chunk store. Always overwrite.
            #
            # @param [String] data
            # @return [Fixnum] length of the data after writing
            def write!(data)
              raise NotImplementedError
            end

            # Append data to chunk store
            #
            # @param [String] data
            # @return [Fixnum] length of the appended
            def append!(data)
              raise NotImplementedError
            end

            # Truncate data to chunk store
            #
            # @param [String] offset
            def truncate!(offset)
              raise NotImplementedError
            end

            # Delete data from chunk store
            #
            # @param [String] offset
            def delete!
              raise NotImplementedError
            end

            def filled?
              size == params[:buffer_size]
            end
          end
        end
      end
    end
  end
end
