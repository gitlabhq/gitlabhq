# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Sbom
        class Source
          attr_reader :source_type, :data

          def initialize(type:, data:)
            @source_type = type
            @data = data
          end

          def source_file_path
            data.dig('source_file', 'path')
          end

          def input_file_path
            data.dig('input_file', 'path')
          end

          def packager
            data.dig('package_manager', 'name')
          end

          def language
            data.dig('language', 'name')
          end
        end
      end
    end
  end
end
