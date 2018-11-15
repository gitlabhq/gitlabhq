# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Artifacts
        module Adapters
          class RawStream
            attr_reader :stream

            InvalidStreamError = Class.new(StandardError)

            def initialize(stream)
              raise InvalidStreamError, "Stream is required" unless stream

              @stream = stream
            end

            def each_blob
              stream.seek(0)

              yield(stream.read, 'raw') unless stream.eof?
            end
          end
        end
      end
    end
  end
end
