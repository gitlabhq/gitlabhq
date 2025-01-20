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
          helpers ::API::Helpers::Packages::Npm

          helpers do
            include Gitlab::Utils::StrongMemoize

            def project_id_or_nil
              return unless group_or_namespace

              finder = ::Packages::Npm::PackageFinder.new(
                namespace: group_or_namespace,
                params: { package_name: params[:package_name] }
              )

              finder.last&.project_id
            end
            strong_memoize_attr :project_id_or_nil

            def project
              # Simulate the same behavior as #user_project by re-using #find_project!
              # but take care if the project_id is nil as #find_project! is not designed
              # to handle it.
              project_id = project_id_or_nil

              not_found!('Project') unless project_id

              find_project!(project_id)
            end
            strong_memoize_attr :project
          end

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
          route_setting :authorization, job_token_policies: :read_packages
          get '*package_name', format: false, requirements: ::API::Helpers::Packages::Npm::NPM_ENDPOINT_REQUIREMENTS do
            package_name = declared_params[:package_name]
            packages =
              if Feature.enabled?(:npm_allow_packages_in_multiple_projects, group_or_namespace)
                ::Packages::Npm::PackageFinder.new(namespace: group_or_namespace,
                  params: { package_name: package_name }).execute
              else
                ::Packages::Npm::PackageFinder.new(project: project_or_nil,
                  params: { package_name: package_name }).execute
              end

            # In order to redirect a request, packages should not exist (without taking the user into account).
            redirect_request = project_or_nil.blank? || packages.empty?

            redirect_registry_request(
              forward_to_registry: redirect_request,
              package_type: :npm,
              target: project_or_nil,
              package_name: package_name
            ) do
              authorize_job_token_policies!(project_or_nil) if project_or_nil

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
