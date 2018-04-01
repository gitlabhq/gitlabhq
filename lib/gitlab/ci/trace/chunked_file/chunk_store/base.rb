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
              size == params[:buffer_size]
            end
          end
        end
      end
    end
  end
end
