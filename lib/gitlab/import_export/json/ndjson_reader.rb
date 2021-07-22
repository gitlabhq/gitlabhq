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

        # This can be removed once legacy_reader is deprecated.
        def legacy?
          false
        end

        def consume_attributes(importable_path)
          # This reads from `tree/project.json`
          path = file_path("#{importable_path}.json")
          data = File.read(path, MAX_JSON_DOCUMENT_SIZE)
          json_decode(data)
        end

        def consume_relation(importable_path, key, mark_as_consumed: true)
          Enumerator.new do |documents|
            next if mark_as_consumed && !@consumed_relations.add?("#{importable_path}/#{key}")

            # This reads from `tree/project/merge_requests.ndjson`
            path = file_path(importable_path, "#{key}.ndjson")

            next unless File.exist?(path)

            File.foreach(path, MAX_JSON_DOCUMENT_SIZE).with_index do |line, line_num|
              documents << [json_decode(line), line_num]
            end
          end
        end

        private

        def json_decode(string)
          Gitlab::Json.parse(string)
        rescue JSON::ParserError => e
          Gitlab::ErrorTracking.log_exception(e)
          raise Gitlab::ImportExport::Error, 'Incorrect JSON format'
        end

        def file_path(*path)
          File.join(dir_path, *path)
        end
      end
    end
  end
end
