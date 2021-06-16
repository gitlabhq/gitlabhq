# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Json
      class LegacyWriter
        include Gitlab::ImportExport::CommandLineUtil

        attr_reader :path

        def initialize(path, allowed_path:)
          @path = path
          @keys = Set.new

          # This is legacy writer, to be used in transition
          # period before `.ndjson`,
          # we strong validate what is being written
          @allowed_path = allowed_path

          mkdir_p(File.dirname(@path))
          file.write('{}')
        end

        def close
          @file&.close
          @file = nil
        end

        def write_attributes(exportable_path, hash)
          unless exportable_path == @allowed_path
            raise ArgumentError, "Invalid #{exportable_path}"
          end

          hash.each do |key, value|
            write(key, value)
          end
        end

        def write_relation(exportable_path, key, value)
          unless exportable_path == @allowed_path
            raise ArgumentError, "Invalid #{exportable_path}"
          end

          write(key, value)
        end

        def write_relation_array(exportable_path, key, items)
          unless exportable_path == @allowed_path
            raise ArgumentError, "Invalid #{exportable_path}"
          end

          write(key, [])

          # rewind by two bytes, to overwrite ']}'
          file.pos = file.size - 2

          items.each_with_index do |item, idx|
            file.write(',') if idx > 0
            file.write(item.to_json)
          end

          file.write(']}')
        end

        private

        def write(key, value)
          raise ArgumentError, "key '#{key}' already written" if @keys.include?(key)

          # rewind by one byte, to overwrite '}'
          file.pos = file.size - 1

          file.write(',') if @keys.any?
          file.write(key.to_json)
          file.write(':')
          file.write(value.to_json)
          file.write('}')

          @keys.add(key)
        end

        def file
          @file ||= File.open(@path, "wb")
        end
      end
    end
  end
end
