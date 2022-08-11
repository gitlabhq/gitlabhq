# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Artifacts
        module Adapters
          class ZipStream
            MAX_DECOMPRESSED_SIZE = 100.megabytes
            MAX_FILES_PROCESSED = 50

            attr_reader :stream

            InvalidStreamError = Class.new(StandardError)

            def initialize(stream)
              raise InvalidStreamError, "Stream is required" unless stream

              @stream = stream
              @files_processed = 0
            end

            def each_blob
              Zip::InputStream.open(stream) do |zio|
                while entry = zio.get_next_entry
                  break if at_files_processed_limit?
                  next unless should_process?(entry)

                  @files_processed += 1

                  yield entry.get_input_stream.read
                end
              end
            end

            private

            def should_process?(entry)
              file?(entry) && !too_large?(entry)
            end

            def file?(entry)
              # Check the file name as a workaround for incorrect
              # file type detection when using InputStream
              # https://github.com/rubyzip/rubyzip/issues/533
              entry.file? && !entry.name.end_with?('/')
            end

            def too_large?(entry)
              entry.size > MAX_DECOMPRESSED_SIZE
            end

            def at_files_processed_limit?
              @files_processed >= MAX_FILES_PROCESSED
            end
          end
        end
      end
    end
  end
end
