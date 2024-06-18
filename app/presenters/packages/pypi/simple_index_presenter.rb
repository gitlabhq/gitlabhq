# frozen_string_literal: true

# Display package repository index acording to PyPI
# Simple API: https://peps.python.org/pep-0503/
module Packages
  module Pypi
    class SimpleIndexPresenter < SimplePresenterBase
      private

      def links
        refs = []

        available_packages.each_batch do |batch|
          batch = batch.preload_pypi_metadatum

          batch.each do |package|
            url = build_pypi_package_path(package)

            refs << package_link(url, package.pypi_metadatum.required_python, package.name)
          end
        end

        refs.join
      end

      def build_pypi_package_path(package)
        params = {
          id: @project_or_group.id,
          package_name: package.normalized_pypi_name
        }

        if project?
          expose_url(
            api_v4_projects_packages_pypi_simple_package_name_path(
              params, true
            )
          )
        elsif group?
          expose_url(
            api_v4_groups___packages_pypi_simple_package_name_path(
              params, true
            )
          )
        end
      end

      def body_name
        @project_or_group.name
      end
    end
  end
end
