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

          def match!
            raise StandardError, 'Metadata file not found !' unless exists?
            paths, metadata = [], []

            each do |line|
              next unless line =~ %r{^#{Regexp.escape(@path)}[^/\s]+/?\s}

              path, meta = line.split(' ')
              paths.push(path)
              metadata.push(meta)
           end

            [paths, metadata.map { |meta| JSON.parse(meta) }]
          end

          def to_string_path
            universe, metadata = match!
            ::Gitlab::StringPath.new(@path, universe, metadata)
          end

          private

          def each
            open do |file|
              gzip = Zlib::GzipReader.new(file)
              gzip.each_line { |line| yield line }
              gzip.close
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
