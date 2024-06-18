# frozen_string_literal: true

# Caution: This Concern has to be included at the end of the API class
# The last route of this Concern has a globbing wildcard that will match all GET urls.
# As such, GET routes declared after the last route of this Concern will not match any url.
module API
  module Concerns
    module Packages
      module NpmNamespaceEndpoints
        extend ActiveSupport::Concern

        included do
          desc 'NPM registry metadata endpoint' do
            detail 'This feature was introduced in GitLab 11.8'
            success [
              { code: 200, model: ::API::Entities::NpmPackage, message: 'Ok' },
              { code: 302, message: 'Found (redirect)' }
            ]
            failure [
              { code: 400, message: 'Bad Request' },
              { code: 401, message: 'Unauthorized' },
              { code: 403, message: 'Forbidden' },
              { code: 404, message: 'Not Found' }
            ]
            tags %w[npm_packages]
          end
          params do
            use :package_name
          end
          route_setting :authentication, job_token_allowed: true, deploy_token_allowed: true,
            authenticate_non_public: true
          get '*package_name', format: false, requirements: ::API::Helpers::Packages::Npm::NPM_ENDPOINT_REQUIREMENTS do
            package_name = declared_params[:package_name]
            packages =
              if Feature.enabled?(:npm_allow_packages_in_multiple_projects, group_or_namespace)
                finder_for_endpoint_scope(package_name).execute
              else
                ::Packages::Npm::PackageFinder.new(package_name, project: project_or_nil).execute
              end

            # In order to redirect a request, packages should not exist (without taking the user into account).
            redirect_request = project_or_nil.blank? || packages.empty?

            redirect_registry_request(
              forward_to_registry: redirect_request,
              package_type: :npm,
              target: project_or_nil,
              package_name: package_name
            ) do
              if Feature.enabled?(:npm_allow_packages_in_multiple_projects, group_or_namespace)
                available_packages_to_user = ::Packages::Npm::PackagesForUserFinder.new(
                  current_user,
                  group_or_namespace,
                  package_name: package_name
                ).execute

                if packages.any? && available_packages_to_user.empty?
                  current_user ? forbidden! : unauthorized!
                end

                packages = available_packages_to_user
              else
                authorize_read_package!(project)
              end

              not_found!('Packages') if packages.empty?

              metadata = generate_metadata_service(packages).execute.payload
              present metadata, with: ::API::Entities::NpmPackage
            end
          end
        end
      end
    end
  end
end
