# frozen_string_literal: true

# Display package version data according to PyPI (PEP 691 JSON)
# Spec: https://peps.python.org/pep-0691/
#
# Generates the JSON body for PyPI simple API package endpoint.
# Basically a list of package download entries for a specific package.
module Packages
  module Pypi
    class SimplePackageVersionsJsonPresenter < SimplePresenterBase
      API_VERSION = '1.0'

      def initialize(packages, project_or_group, package_name:)
        super(packages, project_or_group)
        @package_name = package_name
      end

      def body
        payload = {
          'meta' => { 'api-version' => API_VERSION },
          'name' => body_name,
          'files' => files
        }

        Gitlab::Json.dump(payload)
      end

      private

      def files
        refs = []

        available_packages.each_batch do |relation|
          batch = relation.preload_files_and_file_metadatum
                          .preload_pypi_metadatum

          batch.each do |package|
            package.installable_package_files.each do |file|
              refs << file_entry(package, file)
            end
          end
        end

        refs
      end

      def file_entry(package, file)
        entry = {
          'filename' => file.file_name,
          'url' => build_pypi_package_file_path(file),
          'hashes' => { 'sha256' => file.file_sha256 }
        }

        required_python =
          file.pypi_file_metadatum&.required_python ||
          package.pypi_metadatum&.required_python

        entry['requires-python'] = required_python if required_python.present?
        entry
      end

      def build_pypi_package_file_path(file)
        params = {
          id: @project_or_group.id,
          sha256: file.file_sha256,
          file_identifier: file.file_name
        }

        base =
          if project?
            expose_url(api_v4_projects_packages_pypi_files_file_identifier_path(params, true))
          else
            expose_url(api_v4_groups___packages_pypi_files_file_identifier_path(params, true))
          end

        "#{base}#sha256=#{file.file_sha256}"
      end

      def body_name
        pkg = available_packages.first
        return pkg.normalized_pypi_name if pkg

        @package_name.to_s
      end
    end
  end
end
