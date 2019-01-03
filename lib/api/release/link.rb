# frozen_string_literal: true

module API
  module Release
    class Links < Grape::API
      include PaginationParams

      RELEASE_ENDPOINT_REQUIREMETS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS
        .merge(tag_name: API::NO_SLASH_URL_PART_REGEX)

      before { error!('404 Not Found', 404) unless Feature.enabled?(:releases_page, user_project) }

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource 'projects/:id', requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        resource 'releases/:tag_name', requirements: RELEASE_ENDPOINT_REQUIREMETS do
          resource :assets do
            desc 'Get a list of links of a release' do
              detail 'This feature was introduced in GitLab 11.7.'
              success Entities::Releases::Link
            end
            params do
              use :pagination
            end
            get 'links' do
              authorize! :read_release, release

              present paginate(release.links), with: Entities::Releases::Link
            end

            desc 'Get a link detail of a release' do
              detail 'This feature was introduced in GitLab 11.7.'
              success Entities::Releases::Link
            end
            params do
              requires :link_id, type: String, desc: 'The id of the link'
            end
            get 'links/:link_id' do
              authorize! :read_release, release

              present link, with: Entities::Releases::Link
            end

            desc 'Create a link of a release' do
              detail 'This feature was introduced in GitLab 11.7.'
              success Entities::Releases::Link
            end
            params do
              requires :name, type: String, desc: 'The name of the link'
              requires :url, type: String, desc: 'The URL of the link'
            end
            post 'links' do
              authorize! :create_release, release

              new_link = release.links.create(declared_params(include_missing: false))

              if new_link.persisted?
                present new_link, with: Entities::Releases::Link
              else
                render_api_error!(result[:message], result[:http_status])
              end
            end

            desc 'Update a link of a release' do
              detail 'This feature was introduced in GitLab 11.7.'
              success Entities::Releases::Link
            end
            params do
              requires :link_id, type: Integer, desc: 'The id of the link'
              optional :name, type: String, desc: 'The name of the link'
              optional :url, type: String, desc: 'The URL of the link'
              at_least_one_of :name, :url
            end
            put 'links/:link_id' do
              authorize! :update_release, release

              if link.update(declared_params(include_missing: false))
                present link, with: Entities::Releases::Link
              else
                render_api_error!(result[:message], result[:http_status])
              end
            end

            desc 'Delete a link of a release' do
              detail 'This feature was introduced in GitLab 11.7.'
              success Entities::Releases::Link
            end
            params do
              requires :link_id, type: Integer, desc: 'The id of the link'
            end
            put 'links/:link_id' do
              authorize! :destroy_release, release

              if link.destroy
                present link, with: Entities::Releases::Link
              else
                render_api_error!(result[:message], result[:http_status])
              end
            end
          end
        end
      end

      helpers do
        def release
          @release ||= user_project.releases.find_by_tag(params[:tag_name])
        end

        def link
          @link ||= release.links.find(params[:link_id])
        end
      end
    end
  end
end
