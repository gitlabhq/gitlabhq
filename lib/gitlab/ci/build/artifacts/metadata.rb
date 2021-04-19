# frozen_string_literal: true

require 'zlib'
require 'json'

module Gitlab
  module Ci
    module Build
      module Artifacts
        class Metadata
          ParserError = Class.new(StandardError)
          InvalidStreamError = Class.new(StandardError)

          VERSION_PATTERN = /^[\w\s]+(\d+\.\d+\.\d+)/.freeze
          INVALID_PATH_PATTERN = %r{(^\.?\.?/)|(/\.?\.?/)}.freeze

          attr_reader :stream, :path, :full_version

          def initialize(stream, path, **opts)
            @stream = stream
            @path = path
            @opts = opts
            @full_version = read_version
          end

          def version
            @full_version.match(VERSION_PATTERN)[1]
          end

          def errors
            gzip do |gz|
              read_string(gz) # version
              errors = read_string(gz)
              raise ParserError, 'Errors field not found!' unless errors

              begin
                Gitlab::Json.parse(errors)
              rescue JSON::ParserError
                raise ParserError, 'Invalid errors field!'
              end
            end
          end

          def find_entries!
            gzip do |gz|
              2.times { read_string(gz) } # version and errors fields
              match_entries(gz)
            end
          end

          def to_entry
            entries = find_entries!
            Entry.new(@path, entries)
          end

          private

          def match_entries(gz)
            entries = {}

            child_pattern = '[^/]*/?$' unless @opts[:recursive]
            match_pattern = /^#{Regexp.escape(@path)}#{child_pattern}/

            until gz.eof?
              begin
                path = read_string(gz)&.force_encoding('UTF-8')
                meta = read_string(gz)&.force_encoding('UTF-8')

                # We might hit an EOF while reading either value, so we should
                # abort if we don't get any data.
                next unless path && meta
                next unless path.valid_encoding? && meta.valid_encoding?
                next unless path =~ match_pattern
                next if path =~ INVALID_PATH_PATTERN

                entries[path] = Gitlab::Json.parse(meta, symbolize_names: true)
              rescue JSON::ParserError, Encoding::CompatibilityError
                next
              end
            end

            entries
          end

          def read_version
            gzip do |gz|
              version_string = read_string(gz)

              unless version_string
                raise ParserError, 'Artifacts metadata file empty!'
              end

              unless version_string =~ VERSION_PATTERN
                raise ParserError, 'Invalid version!'
              end

              version_string.chomp
            end
          end

          def read_uint32(gz)
            binary = gz.read(4)
            binary.unpack1('L>') if binary
          end

          def read_string(gz)
            string_size = read_uint32(gz)
            return unless string_size

            gz.read(string_size)
          end

          def gzip(&block)
            raise InvalidStreamError, "Invalid stream" unless @stream

            # restart gzip reading
            @stream.seek(0)

            gz = Zlib::GzipReader.new(@stream)
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
