require 'zlib'
require 'json'

module Gitlab
  module Ci
    module Build
      module Artifacts
        class Metadata
          def initialize(file, path)
            @file = file

            @path = path.sub(/^\.\//, '')
            @path << '/' unless path.end_with?('/')
          end

          def exists?
            File.exists?(@file)
          end

          def full_version
            gzip do|gz|
              read_string(gz) do |size|
                raise StandardError, 'Artifacts metadata file empty!' unless size
              end
            end
          end

          def version
            full_version.match(/\w+ (\d+\.\d+\.\d+)/).captures.first
          end

          def errors
            gzip do|gz|
              read_string(gz) # version
              JSON.parse(read_string(gz))
            end
          end

          def match!
            raise StandardError, 'Metadata file not found !' unless exists?

            gzip do |gz|
              read_string(gz) # version field
              read_string(gz) # errors field
              iterate_entries(gz)
            end
          end

          def to_string_path
            universe, metadata = match!
            ::Gitlab::StringPath.new(@path, universe, metadata)
          end

          private

          def iterate_entries(gz)
            paths, metadata = [], []
            
            until gz.eof? do
              begin
                path = read_string(gz)
                meta = read_string(gz)
               
                next unless path =~ %r{^#{Regexp.escape(@path)}[^/\s]*/?$}
                
                paths.push(path)
                metadata.push(JSON.parse(meta, symbolize_names: true))
              rescue JSON::ParserError
                next
              end
            end

            [paths, metadata]
          end

          def read_string_size(gz)
            binary = gz.read(4)
            binary.unpack('L>')[0] if binary
          end

          def read_string(gz)
            string_size = read_string_size(gz)
            yield string_size if block_given?
            return false unless string_size
            gz.read(string_size).chomp
          end

          def gzip
            open do |file|
              gzip = Zlib::GzipReader.new(file)
              result = yield gzip
              gzip.close
              result
            end
          end

          def open
            File.open(@file) { |file| yield file }
          end
        end
      end
    end
  end
end
