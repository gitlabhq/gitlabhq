# frozen_string_literal: true

module API
  module Release
    class Links < ::API::Base
      include PaginationParams

      release_links_tags = %w[release_links]

      RELEASE_ENDPOINT_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS
        .merge(tag_name: API::NO_SLASH_URL_PART_REGEX)

      after_validation { authorize! :read_release, user_project }

      feature_category :release_orchestration
      urgency :low

      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
      end
      resource 'projects/:id', requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        params do
          requires :tag_name, type: String, desc: 'The tag associated with the release'
        end
        resource 'releases/:tag_name', requirements: RELEASE_ENDPOINT_REQUIREMENTS do
          resource :assets do
            desc 'List links of a release' do
              detail 'Get assets as links from a release. This feature was introduced in GitLab 11.7.'
              success Entities::Releases::Link
              failure [
                { code: 401, message: 'Unauthorized' },
                { code: 404, message: 'Not found' }
              ]
              is_array true
              tags release_links_tags
            end
            params do
              use :pagination
            end
            route_setting :authentication, job_token_allowed: true
            route_setting :authorization, job_token_policies: :read_releases
            get 'links' do
              authorize! :read_release, release

              present paginate(release.links.sorted), with: Entities::Releases::Link
            end

            desc 'Create a release link' do
              detail 'Create an asset as a link from a release. This feature was introduced in GitLab 11.7.'
              success Entities::Releases::Link
              failure [
                { code: 400, message: 'Bad request' },
                { code: 401, message: 'Unauthorized' }
              ]
              tags release_links_tags
            end
            params do
              requires :name, type: String, desc: 'The name of the link. Link names must be unique in the release'
              requires :url, type: String, desc: 'The URL of the link. Link URLs must be unique in the release.'
              optional :direct_asset_path, type: String, desc: 'Optional path for a direct asset link'
              optional :filepath, type: String, desc: 'Deprecated: optional path for a direct asset link'
              optional :link_type,
                type: String,
                values: %w[other runbook image package],
                default: 'other',
                desc: 'The type of the link: `other`, `runbook`, `image`, or `package`. Defaults to `other`'
            end
            route_setting :authentication, job_token_allowed: true
            route_setting :authorization, job_token_policies: :admin_releases
            post 'links' do
              result = ::Releases::Links::CreateService
                .new(release, current_user, declared_params(include_missing: false))
                .execute

              if result.success?
                present result.payload[:link], with: Entities::Releases::Link
              elsif result.reason == ::Releases::Links::REASON_FORBIDDEN
                forbidden!
              else
                render_api_error!(result.message, 400)
              end
            end

            params do
              requires :link_id, type: Integer, desc: 'The ID of the link'
            end
            resource 'links/:link_id' do
              desc 'Get a release link' do
                detail 'Get an asset as a link from a release. This feature was introduced in GitLab 11.7.'
                success Entities::Releases::Link
                failure [
                  { code: 401, message: 'Unauthorized' },
                  { code: 404, message: 'Not found' }
                ]
                tags release_links_tags
              end
              route_setting :authentication, job_token_allowed: true
              route_setting :authorization, job_token_policies: :read_releases
              get do
                authorize! :read_release, release

                present link, with: Entities::Releases::Link
              end

              desc 'Update a release link' do
                detail 'Update an asset as a link from a release. This feature was introduced in GitLab 11.7.'
                success Entities::Releases::Link
                failure [
                  { code: 400, message: 'Bad request' },
                  { code: 401, message: 'Unauthorized' }
                ]
                tags release_links_tags
              end
              params do
                optional :name, type: String, desc: 'The name of the link'
                optional :url, type: String, desc: 'The URL of the link'
                optional :direct_asset_path, type: String, desc: 'Optional path for a direct asset link'
                optional :filepath, type: String, desc: 'Deprecated: optional path for a direct asset link'
                optional :link_type,
                  type: String,
                  values: %w[other runbook image package],
                  default: 'other',
                  desc: 'The type of the link: `other`, `runbook`, `image`, or `package`. Defaults to `other`'

                at_least_one_of :name, :url
              end
              route_setting :authentication, job_token_allowed: true
              route_setting :authorization, job_token_policies: :admin_releases
              put do
                result = ::Releases::Links::UpdateService
                  .new(release, current_user, declared_params(include_missing: false))
                  .execute(link)

                if result.success?
                  present result.payload[:link], with: Entities::Releases::Link
                elsif result.reason == ::Releases::Links::REASON_FORBIDDEN
                  forbidden!
                else
                  render_api_error!(result.message, 400)
                end
              end

              desc 'Delete a release link' do
                detail 'Deletes an asset as a link from a release. This feature was introduced in GitLab 11.7.'
                success Entities::Releases::Link
                failure [
                  { code: 400, message: 'Bad request' },
                  { code: 401, message: 'Unauthorized' }
                ]
                tags release_links_tags
              end
              route_setting :authentication, job_token_allowed: true
              route_setting :authorization, job_token_policies: :admin_releases
              delete do
                result = ::Releases::Links::DestroyService
                  .new(release, current_user)
                  .execute(link)

                if result.success?
                  present result.payload[:link], with: Entities::Releases::Link
                elsif result.reason == ::Releases::Links::REASON_FORBIDDEN
                  forbidden!
                else
                  render_api_error!(result.message, 400)
                end
              end
            end
          end
        end
      end

      helpers do
        def release
          @release ||= user_project.releases.find_by_tag!(declared_params(include_parent_namespaces: true)[:tag_name])
        end

        def link
          @link ||= release.links.find(declared_params(include_parent_namespaces: true)[:link_id])
        end
      end
    end
  end
end
