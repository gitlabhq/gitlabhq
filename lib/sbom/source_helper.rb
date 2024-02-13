# frozen_string_literal: true

module Sbom
  module SourceHelper
    def source_file_path
      data.dig('source_file', 'path')
    end

    def input_file_path
      case source_type.to_sym
      when :dependency_scanning
        data.dig('input_file', 'path')
      when :trivy
        data['FilePath']
      end
    end

    def packager
      case source_type.to_sym
      when :dependency_scanning
        data.dig('package_manager', 'name')
      when :trivy
        ::Enums::Sbom.package_manager_from_trivy_pkg_type(data['PkgType'])
      end
    end

    def language
      data.dig('language', 'name')
    end

    def image_name
      data.dig('image', 'name')
    end

    def image_tag
      return unless image_name.present?

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
