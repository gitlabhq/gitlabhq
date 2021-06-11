# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Json
      class NdjsonWriter
        include Gitlab::ImportExport::CommandLineUtil

        def initialize(dir_path)
          @dir_path = dir_path
        end

        def close
        end

        def write_attributes(exportable_path, hash)
          # It will create:
          # tree/project.json
          with_file("#{exportable_path}.json") do |file|
            file.write(hash.to_json)
          end
        end

        def write_relation(exportable_path, relation, value)
          # It will create:
          # tree/project/ci_cd_setting.ndjson
          with_file(exportable_path, "#{relation}.ndjson") do |file|
            file.write(value.to_json)
          end
        end

        def write_relation_array(exportable_path, relation, items)
          # It will create:
          # tree/project/merge_requests.ndjson
          with_file(exportable_path, "#{relation}.ndjson") do |file|
            items.each do |item|
              file.write(item.to_json)
              file.write("\n")
            end
          end
        end

        private

        def with_file(*path)
          file_path = File.join(@dir_path, *path)
          raise ArgumentError, "The #{file_path} already exist" if File.exist?(file_path)

          # ensure that path is created
          mkdir_p(File.dirname(file_path))

          File.open(file_path, "wb") do |file|
            yield(file)
          end
        end
      end
    end
  end
end
