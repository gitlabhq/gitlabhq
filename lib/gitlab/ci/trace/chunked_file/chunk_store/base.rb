module Gitlab
  module Ci
    class Trace
      module ChunkedFile
        module ChunkStore
          class Base
            attr_reader :buffer_size
            attr_reader :chunk_start
            attr_reader :url

            def initialize(*identifiers, **params)
              @buffer_size = params[:buffer_size]
              @chunk_start = params[:chunk_start]
              @url = params[:url]
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

            def write!(data)
              raise NotImplementedError
            end

            def append!(data)
              raise NotImplementedError
            end

            def truncate!(offset)
              raise NotImplementedError
            end

            def delete!
              raise NotImplementedError
            end

            def filled?
              size == buffer_size
            end
          end
        end
      end
    end
  end
end
