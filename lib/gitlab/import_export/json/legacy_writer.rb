# frozen_string_literal: true

module Gitlab
  module ImportExport
    module JSON
      class LegacyWriter
        include Gitlab::ImportExport::CommandLineUtil

        attr_reader :path

        def initialize(path)
          @path = path
          @last_array = nil
          @keys = Set.new

          mkdir_p(File.dirname(@path))
          file.write('{}')
        end

        def close
          @file&.close
          @file = nil
        end

        def set(hash)
          hash.each do |key, value|
            write(key, value)
          end
        end

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
          @last_array = nil
          @last_array_count = nil
        end

        def append(key, value)
          unless @last_array == key
            write(key, [])

            @last_array = key
            @last_array_count = 0
          end

          # rewind by two bytes, to overwrite ']}'
          file.pos = file.size - 2

          file.write(',') if @last_array_count > 0
          file.write(value.to_json)
          file.write(']}')
          @last_array_count += 1
        end

        private

        def file
          @file ||= File.open(@path, "wb")
        end
      end
    end
  end
end
