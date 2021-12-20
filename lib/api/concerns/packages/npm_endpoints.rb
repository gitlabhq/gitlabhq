# frozen_string_literal: true

# NPM Package Manager Client API
#
# These API endpoints are not consumed directly by users, so there is no documentation for the
# individual endpoints. They are called by the NPM package manager client when users run commands
# like `npm install` or `npm publish`. The usage of the GitLab NPM registry is documented here:
# https://docs.gitlab.com/ee/user/packages/npm_registry/
#
# Technical debt: https://gitlab.com/gitlab-org/gitlab/issues/35798
#
# Caution: This Concern has to be included at the end of the API class
# The last route of this Concern has a globbing wildcard that will match all urls.
# As such, routes declared after the last route of this Concern will not match any url.
module API
  module Concerns
    module Packages
      module NpmEndpoints
        extend ActiveSupport::Concern

        included do
          helpers ::API::Helpers::Packages::DependencyProxyHelpers

          before do
            require_packages_enabled!
            authenticate_non_get!
          end

          params do
            requires :package_name, type: String, desc: 'Package name'
          end
          namespace '-/package/*package_name' do
            desc 'Get all tags for a given an NPM package' do
              detail 'This feature was introduced in GitLab 12.7'
              success ::API::Entities::NpmPackageTag
            end
            get 'dist-tags', format: false, requirements: ::API::Helpers::Packages::Npm::NPM_ENDPOINT_REQUIREMENTS do
              package_name = params[:package_name]

              bad_request_missing_attribute!('Package Name') if package_name.blank?

              authorize_read_package!(project)

              packages = ::Packages::Npm::PackageFinder.new(package_name, project: project)
                                                       .execute

              not_found! if packages.empty?

              present ::Packages::Npm::PackagePresenter.new(package_name, packages),
                      with: ::API::Entities::NpmPackageTag
            end

            params do
              requires :tag, type: String, desc: "Package dist-tag"
            end
            namespace 'dist-tags/:tag', requirements: ::API::Helpers::Packages::Npm::NPM_ENDPOINT_REQUIREMENTS do
              desc 'Create or Update the given tag for the given NPM package and version' do
                detail 'This feature was introduced in GitLab 12.7'
              end
              put format: false do
                package_name = params[:package_name]
                version = env['api.request.body']
                tag = params[:tag]

                bad_request_missing_attribute!('Package Name') if package_name.blank?
                bad_request_missing_attribute!('Version') if version.blank?
                bad_request_missing_attribute!('Tag') if tag.blank?

                authorize_create_package!(project)

                package = ::Packages::Npm::PackageFinder.new(package_name, project: project)
                                                        .find_by_version(version)
                not_found!('Package') unless package

                ::Packages::Npm::CreateTagService.new(package, tag).execute

                no_content!
              end

              desc 'Deletes the given tag' do
                detail 'This feature was introduced in GitLab 12.7'
              end
              delete format: false do
                package_name = params[:package_name]
                tag = params[:tag]

                bad_request_missing_attribute!('Package Name') if package_name.blank?
                bad_request_missing_attribute!('Tag') if tag.blank?

                authorize_destroy_package!(project)

                package_tag = ::Packages::TagsFinder
                  .new(project, package_name, package_type: :npm)
                  .find_by_name(tag)

                not_found!('Package tag') unless package_tag

                ::Packages::RemoveTagService.new(package_tag).execute

                no_content!
              end
            end
          end

          desc 'NPM registry metadata endpoint' do
            detail 'This feature was introduced in GitLab 11.8'
          end
          params do
            requires :package_name, type: String, desc: 'Package name'
          end
          route_setting :authentication, job_token_allowed: true, deploy_token_allowed: true
          get '*package_name', format: false, requirements: ::API::Helpers::Packages::Npm::NPM_ENDPOINT_REQUIREMENTS do
            package_name = params[:package_name]
            packages = ::Packages::Npm::PackageFinder.new(package_name, project: project_or_nil)
                                                     .execute

            redirect_request = project_or_nil.blank? || packages.empty?

            redirect_registry_request(redirect_request, :npm, package_name: package_name) do
              authorize_read_package!(project)

              not_found!('Packages') if packages.empty?

              present ::Packages::Npm::PackagePresenter.new(package_name, packages),
                with: ::API::Entities::NpmPackage
            end
          end
        end
      end
    end
  end
end
