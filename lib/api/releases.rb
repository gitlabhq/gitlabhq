# frozen_string_literal: true

module API
  class Releases < Grape::API
    include PaginationParams

    RELEASE_ENDPOINT_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS
      .merge(tag_name: API::NO_SLASH_URL_PART_REGEX)

    before { authorize_read_releases! }

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

        present paginate(releases), with: Entities::Release, current_user: current_user
      end

      desc 'Get a single project release' do
        detail 'This feature was introduced in GitLab 11.7.'
        success Entities::Release
      end
      params do
        requires :tag_name, type: String, desc: 'The name of the tag', as: :tag
      end
      get ':id/releases/:tag_name', requirements: RELEASE_ENDPOINT_REQUIREMENTS do
        authorize_download_code!

        present release, with: Entities::Release, current_user: current_user
      end

      desc 'Create a new release' do
        detail 'This feature was introduced in GitLab 11.7.'
        success Entities::Release
      end
      params do
        requires :tag_name,    type: String, desc: 'The name of the tag', as: :tag
        optional :name,        type: String, desc: 'The name of the release'
        requires :description, type: String, desc: 'The release notes'
        optional :ref,         type: String, desc: 'The commit sha or branch name'
        optional :assets, type: Hash do
          optional :links, type: Array do
            requires :name, type: String
            requires :url, type: String
          end
        end
        optional :milestones, type: Array, desc: 'The titles of the related milestones', default: []
        optional :released_at, type: DateTime, desc: 'The date when the release will be/was ready. Defaults to the current time.'
      end
      route_setting :authentication, job_token_allowed: true
      post ':id/releases' do
        authorize_create_release!

        result = ::Releases::CreateService
          .new(user_project, current_user, declared_params(include_missing: false))
          .execute

        if result[:status] == :success
          log_release_created_audit_event(result[:release])

          present result[:release], with: Entities::Release, current_user: current_user
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end

      desc 'Update a release' do
        detail 'This feature was introduced in GitLab 11.7.'
        success Entities::Release
      end
      params do
        requires :tag_name,    type: String, desc: 'The name of the tag', as: :tag
        optional :name,        type: String, desc: 'The name of the release'
        optional :description, type: String, desc: 'Release notes with markdown support'
        optional :released_at, type: DateTime, desc: 'The date when the release will be/was ready.'
        optional :milestones,  type: Array, desc: 'The titles of the related milestones'
      end
      put ':id/releases/:tag_name', requirements: RELEASE_ENDPOINT_REQUIREMENTS do
        authorize_update_release!

        result = ::Releases::UpdateService
          .new(user_project, current_user, declared_params(include_missing: false))
          .execute

        if result[:status] == :success
          log_release_updated_audit_event
          log_release_milestones_updated_audit_event if result[:milestones_updated]

          present result[:release], with: Entities::Release, current_user: current_user
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end

      desc 'Delete a release' do
        detail 'This feature was introduced in GitLab 11.7.'
        success Entities::Release
      end
      params do
        requires :tag_name, type: String, desc: 'The name of the tag', as: :tag
      end
      delete ':id/releases/:tag_name', requirements: RELEASE_ENDPOINT_REQUIREMENTS do
        authorize_destroy_release!

        result = ::Releases::DestroyService
          .new(user_project, current_user, declared_params(include_missing: false))
          .execute

        if result[:status] == :success
          present result[:release], with: Entities::Release, current_user: current_user
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end
    end

    helpers do
      def authorize_create_release!
        authorize! :create_release, user_project
      end

      def authorize_read_releases!
        authorize! :read_release, user_project
      end

      def authorize_read_release!
        authorize! :read_release, release
      end

      def authorize_update_release!
        authorize! :update_release, release
      end

      def authorize_destroy_release!
        authorize! :destroy_release, release
      end

      def authorize_download_code!
        authorize! :download_code, release
      end

      def release
        @release ||= user_project.releases.find_by_tag(params[:tag])
      end

      def log_release_created_audit_event(release)
        # This is a separate method so that EE can extend its behaviour
      end

      def log_release_updated_audit_event
        # This is a separate method so that EE can extend its behaviour
      end

      def log_release_milestones_updated_audit_event
        # This is a separate method so that EE can extend its behaviour
      end
    end
  end
end

API::Releases.prepend_if_ee('EE::API::Releases')
