# frozen_string_literal: true

module API
  module Release
    class Links < Grape::API
      include PaginationParams

      RELEASE_ENDPOINT_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS
        .merge(tag_name: API::NO_SLASH_URL_PART_REGEX)

      before { authorize! :read_release, user_project }

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource 'projects/:id', requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        params do
          requires :tag_name, type: String, desc: 'The name of the tag', as: :tag
        end
        resource 'releases/:tag_name', requirements: RELEASE_ENDPOINT_REQUIREMENTS do
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

              present paginate(release.links.sorted), with: Entities::Releases::Link
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
                render_api_error!(new_link.errors.messages, 400)
              end
            end

            params do
              requires :link_id, type: String, desc: 'The id of the link'
            end
            resource 'links/:link_id' do
              desc 'Get a link detail of a release' do
                detail 'This feature was introduced in GitLab 11.7.'
                success Entities::Releases::Link
              end
              get do
                authorize! :read_release, release

                present link, with: Entities::Releases::Link
              end

              desc 'Update a link of a release' do
                detail 'This feature was introduced in GitLab 11.7.'
                success Entities::Releases::Link
              end
              params do
                optional :name, type: String, desc: 'The name of the link'
                optional :url, type: String, desc: 'The URL of the link'
                at_least_one_of :name, :url
              end
              put do
                authorize! :update_release, release

                if link.update(declared_params(include_missing: false))
                  present link, with: Entities::Releases::Link
                else
                  render_api_error!(link.errors.messages, 400)
                end
              end

              desc 'Delete a link of a release' do
                detail 'This feature was introduced in GitLab 11.7.'
                success Entities::Releases::Link
              end
              delete do
                authorize! :destroy_release, release

                if link.destroy
                  present link, with: Entities::Releases::Link
                else
                  render_api_error!(link.errors.messages, 400)
                end
              end
            end
          end
        end
      end

      helpers do
        def release
          @release ||= user_project.releases.find_by_tag!(params[:tag])
        end

        def link
          @link ||= release.links.find(params[:link_id])
        end
      end
    end
  end
end
