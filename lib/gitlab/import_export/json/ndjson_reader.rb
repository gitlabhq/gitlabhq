# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Json
      class NdjsonReader
        MAX_JSON_DOCUMENT_SIZE = 50.megabytes

        attr_reader :dir_path

        def initialize(dir_path)
          @dir_path = dir_path
          @consumed_relations = Set.new
        end

        def exist?
          Dir.exist?(@dir_path)
        end

        def consume_attributes(importable_path)
          # This reads from `tree/project.json`
          path = file_path("#{importable_path}.json")

          if !File.exist?(path) || Gitlab::Utils::FileInfo.linked?(path)
            raise Gitlab::ImportExport::Error, 'Invalid file'
          end

          data = File.read(path, max_json_size_with_error_buffer)
          json_decode(data, path)
        end

        def consume_relation(importable_path, key, mark_as_consumed: true)
          Enumerator.new do |documents|
            next if mark_as_consumed && !@consumed_relations.add?("#{importable_path}/#{key}")

            # This reads from `tree/project/merge_requests.ndjson`
            path = file_path(importable_path, "#{key}.ndjson")

            next if !File.exist?(path) || Gitlab::Utils::FileInfo.linked?(path)

            File.foreach(path, max_json_size_with_error_buffer).with_index do |line, line_num|
              documents << [json_decode(line, path), line_num]
            end
          end
        end

        private

        # Truncate file reads just above the limit to distinguish between oversized JSON and JSON exactly at the limit
        def max_json_size_with_error_buffer
          MAX_JSON_DOCUMENT_SIZE + 1
        end

        def json_decode(string, path)
          Gitlab::Json.parse(string)
        rescue JSON::ParserError => e
          Gitlab::ErrorTracking.log_exception(e)

          raise Gitlab::ImportExport::Error, 'Incorrect JSON format' if string.bytesize <= MAX_JSON_DOCUMENT_SIZE

          raise Gitlab::ImportExport::Error,
            "JSON exceeds #{ActiveSupport::NumberHelper.number_to_human_size(MAX_JSON_DOCUMENT_SIZE)} limit " \
              "in #{File.basename(path)}"
        end

        def file_path(*path)
          File.join(dir_path, *path)
        end
      end
    end
  end
end
