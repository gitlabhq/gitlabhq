# frozen_string_literal: true

module API
  module Helpers
    module Packages
      module Nuget
        def find_packages(package_name)
          packages = package_finder(package_name).execute

          not_found!('Packages') unless packages.exists?

          packages
        end

        def find_package(package_name, package_version)
          package = package_finder(package_name, package_version).execute.first

          not_found!('Package') unless package

          package
        end

        def package_finder(package_name, package_version = nil)
          ::Packages::Nuget::PackageFinder.new(
            current_user,
            project_or_group,
            package_name: package_name,
            package_version: package_version,
            client_version: headers['X-Nuget-Client-Version']
          )
        end

        def search_packages(_search_term, search_options)
          ::Packages::Nuget::SearchService
            .new(current_user, project_or_group, params[:q], search_options)
            .execute
        end
      end
    end
  end
end
