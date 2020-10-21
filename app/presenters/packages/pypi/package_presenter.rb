# frozen_string_literal: true

# Display package version data acording to PyPI
# Simple API: https://warehouse.pypa.io/api-reference/legacy/#simple-project-api
module Packages
  module Pypi
    class PackagePresenter
      include API::Helpers::RelatedResourcesHelpers

      def initialize(packages, project)
        @packages = packages
        @project = project
      end

      # Returns the HTML body for PyPI simple API.
      # Basically a list of package download links for a specific
      # package
      def body
        <<-HTML
        <!DOCTYPE html>
        <html>
          <head>
            <title>Links for #{escape(name)}</title>
          </head>
          <body>
            <h1>Links for #{escape(name)}</h1>
            #{links}
          </body>
        </html>
        HTML
      end

      private

      def links
        refs = []

        @packages.map do |package|
          package.package_files.each do |file|
            url = build_pypi_package_path(file)

            refs << package_link(url, package.pypi_metadatum.required_python, file.file_name)
          end
        end

        refs.join
      end

      def package_link(url, required_python, filename)
        "<a href=\"#{url}\" data-requires-python=\"#{escape(required_python)}\">#{filename}</a><br>"
      end

      def build_pypi_package_path(file)
        expose_url(
          api_v4_projects_packages_pypi_files_file_identifier_path(
            {
              id: @project.id,
              sha256: file.file_sha256,
              file_identifier: file.file_name
            },
            true
          )
        ) + "#sha256=#{file.file_sha256}"
      end

      def name
        @packages.first.name
      end

      def escape(str)
        ERB::Util.html_escape(str)
      end
    end
  end
end
