# frozen_string_literal: true

# Display package version data acording to PyPI
# Simple API: https://warehouse.pypa.io/api-reference/legacy/#simple-project-api
# Generates the HTML body for PyPI simple API.
# Basically a list of package download links for a specific
# package
module Packages
  module Pypi
    class SimplePackageVersionsPresenter < SimplePresenterBase
      private

      def links
        refs = []

        available_packages.each_batch do |relation|
          batch = relation.preload_files
                          .preload_pypi_metadatum

          batch.each do |package|
            package_files = package.installable_package_files

            package_files.each do |file|
              url = build_pypi_package_file_path(file)

              refs << package_link(url, package.pypi_metadatum.required_python, file.file_name)
            end
          end
        end

        refs.join
      end

      def build_pypi_package_file_path(file)
        params = {
          id: @project_or_group.id,
          sha256: file.file_sha256,
          file_identifier: file.file_name
        }

        if project?
          expose_url(
            api_v4_projects_packages_pypi_files_file_identifier_path(
              params, true
            )
          ) + "#sha256=#{file.file_sha256}"
        elsif group?
          expose_url(
            api_v4_groups___packages_pypi_files_file_identifier_path(
              params, true
            )
          ) + "#sha256=#{file.file_sha256}"
        end
      end

      def body_name
        @packages.first.name
      end
    end
  end
end
