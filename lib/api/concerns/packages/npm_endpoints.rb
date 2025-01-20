# frozen_string_literal: true

# NPM Package Manager Client API
#
# These API endpoints are not consumed directly by users, so there is no documentation for the
# individual endpoints. They are called by the NPM package manager client when users run commands
# like `npm install` or `npm publish`. The usage of the GitLab NPM registry is documented here:
# https://docs.gitlab.com/ee/user/packages/npm_registry/
#
# Technical debt: https://gitlab.com/gitlab-org/gitlab/issues/35798
module API
  module Concerns
    module Packages
      module NpmEndpoints
        extend ActiveSupport::Concern

        included do
          helpers ::API::Helpers::Packages::DependencyProxyHelpers
          helpers ::API::Helpers::Packages::Npm

          rescue_from ActiveRecord::RecordInvalid do |e|
            render_structured_api_error!({ message: e.message, error: e.message }, 400)
          end

          before do
            require_packages_enabled!
            authenticate_non_get!
          end

          helpers do
            params :package_name do
              requires :package_name, type: String, file_path: true, desc: 'Package name',
                documentation: { example: 'mypackage' }
            end

            def redirect_or_present_audit_report
              redirect_registry_request(
                forward_to_registry: true,
                package_type: :npm,
                path: options[:path][0],
                body: Gitlab::Json.dump(request.POST),
                target: project_or_nil,
                method: route.request_method
              ) do
                authorize_read_package!(project)

                status :ok
                present []
              end
            end

            def generate_metadata_service(packages)
              ::Packages::Npm::GenerateMetadataService.new(params[:package_name], packages)
            end

            def bad_request_missing_attribute!(attribute)
              reason = "\"#{attribute}\" not given"
              message = "400 Bad request - #{reason}"
              render_structured_api_error!({ message: message, error: reason }, 400)
            end
          end

          params do
            requires :package_name, type: String, desc: 'Package name'
          end
          namespace '-/package/*package_name' do
            desc 'Get all tags for a given an NPM package' do
              detail 'This feature was introduced in GitLab 12.7'
              success [
                { code: 200, model: ::API::Entities::NpmPackageTag }
              ]
              failure [
                { code: 400, message: 'Bad Request' },
                { code: 401, message: 'Unauthorized' },
                { code: 403, message: 'Forbidden' },
                { code: 404, message: 'Not Found' }
              ]
              tags %w[npm_packages]
            end
            route_setting :authentication, job_token_allowed: true, deploy_token_allowed: true,
              authenticate_non_public: true
            route_setting :authorization, job_token_policies: :read_packages
            get 'dist-tags', format: false, requirements: ::API::Helpers::Packages::Npm::NPM_ENDPOINT_REQUIREMENTS do
              package_name = params[:package_name]

              bad_request_missing_attribute!('Package Name') if package_name.blank?

              authorize_read_package!(project)

              packages = ::Packages::Npm::PackageFinder.new(project: project, params: { package_name: package_name })
                                                       .execute

              not_found!('Package') if packages.empty?

              track_package_event(:list_tags, :npm, project: project, namespace: project.namespace)

              metadata = generate_metadata_service(packages).execute(only_dist_tags: true).payload
              present metadata, with: ::API::Entities::NpmPackageTag
            end

            params do
              requires :tag, type: String, desc: "Package dist-tag"
            end
            namespace 'dist-tags/:tag', requirements: ::API::Helpers::Packages::Npm::NPM_ENDPOINT_REQUIREMENTS do
              desc 'Create or Update the given tag for the given NPM package and version' do
                detail 'This feature was introduced in GitLab 12.7'
                success code: 204
                failure [
                  { code: 400, message: 'Bad Request' },
                  { code: 401, message: 'Unauthorized' },
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not Found' }
                ]
                tags %w[npm_packages]
              end
              route_setting :authentication, job_token_allowed: true, deploy_token_allowed: true
              route_setting :authorization, job_token_policies: :admin_packages
              put format: false do
                package_name = params[:package_name]
                version = env['api.request.body']
                tag = params[:tag]

                bad_request_missing_attribute!('Package Name') if package_name.blank?
                bad_request_missing_attribute!('Version') if version.blank?
                bad_request_missing_attribute!('Tag') if tag.blank?

                authorize_create_package!(project)

                package = ::Packages::Npm::PackageFinder.new(
                  project: project, params: { package_name: package_name, package_version: version }
                ).last
                not_found!('Package') unless package

                track_package_event(:create_tag, :npm, project: project, namespace: project.namespace)

                enqueue_sync_metadata_cache_worker(project, package_name)

                ::Packages::Npm::CreateTagService.new(package, tag).execute

                no_content!
              end

              desc 'Deletes the given tag' do
                detail 'This feature was introduced in GitLab 12.7'
                success code: 204
                failure [
                  { code: 400, message: 'Bad Request' },
                  { code: 401, message: 'Unauthorized' },
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not Found' }
                ]
                tags %w[npm_packages]
              end
              route_setting :authentication, job_token_allowed: true, deploy_token_allowed: true
              route_setting :authorization, job_token_policies: :admin_packages
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

                track_package_event(:delete_tag, :npm, project: project, namespace: project.namespace)

                enqueue_sync_metadata_cache_worker(project, package_name)

                ::Packages::RemoveTagService.new(package_tag).execute

                no_content!
              end
            end
          end

          desc 'NPM registry bulk advisory endpoint' do
            detail 'This feature was introduced in GitLab 15.6'
            success [
              { code: 200, message: 'Ok' },
              { code: 307, message: 'Temporary Redirect' }
            ]
            failure [
              { code: 401, message: 'Unauthorized' },
              { code: 403, message: 'Forbidden' },
              { code: 404, message: 'Not Found' }
            ]
            is_array true
            tags %w[npm_packages]
          end
          route_setting :authentication, job_token_allowed: true, deploy_token_allowed: true
          route_setting :authorization, job_token_policies: :read_packages
          post '-/npm/v1/security/advisories/bulk' do
            redirect_or_present_audit_report
          end

          desc 'NPM registry quick audit endpoint' do
            detail 'This feature was introduced in GitLab 15.6'
            success [
              { code: 200, message: 'Ok' },
              { code: 307, message: 'Temporary Redirect' }
            ]
            failure [
              { code: 401, message: 'Unauthorized' },
              { code: 403, message: 'Forbidden' },
              { code: 404, message: 'Not Found' }
            ]
            is_array true
            tags %w[npm_packages]
          end
          route_setting :authentication, job_token_allowed: true, deploy_token_allowed: true
          route_setting :authorization, job_token_policies: :read_packages
          post '-/npm/v1/security/audits/quick' do
            redirect_or_present_audit_report
          end
        end
      end
    end
  end
end
