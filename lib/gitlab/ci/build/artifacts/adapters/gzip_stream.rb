# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Artifacts
        module Adapters
          class GzipStream
            attr_reader :stream

            InvalidStreamError = Class.new(StandardError)

            def initialize(stream)
              raise InvalidStreamError, "Stream is required" unless stream

              @stream = stream
            end

            def each_blob
              stream.seek(0)

              until stream.eof?
                gzip(stream) do |gz|
                  yield gz.read, gz.orig_name
                  unused = gz.unused&.length.to_i
                  # pos has already reached to EOF at the moment
                  # We rewind the pos to the top of unused files
                  # to read next gzip stream, to support multistream archives
                  # https://golang.org/src/compress/gzip/gunzip.go#L117
                  stream.seek(-unused, IO::SEEK_CUR)
                end
              end
            end

            private

            def gzip(stream, &block)
              gz = Zlib::GzipReader.new(stream)
              yield(gz)
            rescue Zlib::Error => e
              raise InvalidStreamError, e.message
            ensure
              gz&.finish
            end
          end
        end
      end
    end
  end
end
