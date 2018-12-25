# frozen_string_literal: true

module API
  class Releases < Grape::API
    include PaginationParams

    RELEASE_ENDPOINT_REQUIREMETS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS.merge(tag_name: API::NO_SLASH_URL_PART_REGEX)

    before { error!('404 Not Found', 404) unless Feature.enabled?(:releases_page, user_project) }
    before { authorize_read_release! }

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a project releases' do
        detail 'This feature was introduced in GitLab 11.7.'
        success Entities::Release
      end
      params do
        use :pagination
      end
      get ':id/releases' do
        releases = ::ReleasesFinder.new(user_project, current_user).execute

        present paginate(releases), with: Entities::Release
      end

      desc 'Get a single project release' do
        detail 'This feature was introduced in GitLab 11.7.'
        success Entities::Release
      end
      params do
        requires :tag_name, type: String, desc: 'The name of the tag'
      end
      get ':id/releases/:tag_name', requirements: RELEASE_ENDPOINT_REQUIREMETS do
        release = user_project.releases.find_by_tag(params[:tag_name])
        not_found!('Release') unless release

        present release, with: Entities::Release
      end

      desc 'Create a new release' do
        detail 'This feature was introduced in GitLab 11.7.'
        success Entities::Release
      end
      params do
        requires :name,                type: String, desc: 'The name of the release'
        requires :tag_name,            type: String, desc: 'The name of the tag', as: :tag
        requires :description,         type: String, desc: 'The release notes'
        optional :ref,                 type: String, desc: 'The commit sha or branch name'
      end
      post ':id/releases' do
        authorize_create_release!

        attributes = declared(params)
        ref = attributes.delete(:ref)
        attributes.delete(:id)

        result = ::CreateReleaseService.new(user_project, current_user, attributes)
          .execute(ref)

        if result[:status] == :success
          present result[:release], with: Entities::Release
        else
          render_api_error!(result[:message], 400)
        end
      end

      desc 'Update a release' do
        detail 'This feature was introduced in GitLab 11.7.'
        success Entities::Release
      end
      params do
        requires :tag_name,    type: String, desc: 'The name of the tag', as: :tag
        requires :name,        type: String, desc: 'The name of the release'
        requires :description, type: String, desc: 'Release notes with markdown support'
      end
      put ':id/releases/:tag_name', requirements: RELEASE_ENDPOINT_REQUIREMETS do
        authorize_update_release!

        attributes = declared(params)
        attributes.delete(:id)
        result = UpdateReleaseService.new(user_project, current_user, attributes).execute

        if result[:status] == :success
          present result[:release], with: Entities::Release
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end

      desc 'Delete a release' do
        detail 'This feature was introduced in GitLab 11.7.'
        success Entities::Release
      end
      params do
        requires :tag_name,    type: String, desc: 'The name of the tag', as: :tag
      end
      delete ':id/releases/:tag_name', requirements: RELEASE_ENDPOINT_REQUIREMETS do
        authorize_update_release!

        attributes = declared(params)
        attributes.delete(:id)
        result = DeleteReleaseService.new(user_project, current_user, attributes).execute

        if result[:status] == :success
          present result[:release], with: Entities::Release
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end
    end
  end
end
