module Gitlab
  module Ci
    class Trace
      module ChunkedFile
        module Concerns
          module Errors
            extend ActiveSupport::Concern

            included do
              WriteError = Class.new(StandardError)
              FailedToGetChunkError = Class.new(StandardError)
            end
          end
        end
      end
    end
  end
end
