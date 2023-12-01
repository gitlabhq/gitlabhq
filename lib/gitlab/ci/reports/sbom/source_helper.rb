# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Sbom
        module SourceHelper
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

          def image_name
            data.dig('image', 'name')
          end

          def image_tag
            data.dig('image', 'tag')
          end

          def operating_system_name
            data.dig('operating_system', 'name')
          end

          def operating_system_version
            data.dig('operating_system', 'version')
          end
        end
      end
    end
  end
end
