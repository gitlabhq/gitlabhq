# frozen_string_literal: true

module API
  module Helpers
    module Packages
      module Nuget
        def find_packages
          packages = package_finder(params[:package_name]).execute

          not_found!('Packages') unless packages.exists?

          packages
        end

        def find_package
          package = package_finder(params[:package_name], params[:package_version]).execute.first

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

        def search_packages
          search_options = {
            include_prerelease_versions: params[:prerelease],
            per_page: params[:take],
            padding: params[:skip]
          }

          ::Packages::Nuget::SearchService
            .new(current_user, project_or_group, params[:q], search_options)
            .execute
        end
      end
    end
  end
end
