# frozen_string_literal: true

module API
  class Releases < ::API::Base
    include PaginationParams

    RELEASE_ENDPOINT_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS
      .merge(tag_name: API::NO_SLASH_URL_PART_REGEX)
    RELEASE_CLI_USER_AGENT = 'GitLab-release-cli'

    before { authorize_read_releases! }

    after { track_release_event }

    feature_category :release_orchestration

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a project releases' do
        detail 'This feature was introduced in GitLab 11.7.'
        named 'get_releases'
        success Entities::Release
      end
      params do
        use :pagination
        optional :order_by, type: String, values: %w[released_at created_at], default: 'released_at',
                            desc: 'Return releases ordered by `released_at` or `created_at`.'
        optional :sort, type: String, values: %w[asc desc], default: 'desc',
                        desc: 'Return releases sorted in `asc` or `desc` order.'
        optional :include_html_description, type: Boolean,
                               desc: 'If `true`, a response includes HTML rendered markdown of the release description.'
      end
      get ':id/releases' do
        releases = ::ReleasesFinder.new(user_project, current_user, declared_params.slice(:order_by, :sort)).execute

        # We cache the serialized payload per user in order to avoid repeated renderings.
        # Since the cached result could contain sensitive information,
        # it will expire in a short interval.
        present_cached paginate(releases),
                        with: Entities::Release,
                        # `current_user` could be absent if the releases are publicly accesible.
                        # We should not use `cache_key` for the user because the version/updated_at
                        # context is unnecessary here.
                        cache_context: -> (_) { "user:{#{current_user&.id}}" },
                        expires_in: 5.minutes,
                        current_user: current_user,
                        include_html_description: params[:include_html_description]
      end

      desc 'Get a single project release' do
        detail 'This feature was introduced in GitLab 11.7.'
        named 'get_release'
        success Entities::Release
      end
      params do
        requires :tag_name, type: String, desc: 'The name of the tag', as: :tag
        optional :include_html_description, type: Boolean,
                               desc: 'If `true`, a response includes HTML rendered markdown of the release description.'
      end
      get ':id/releases/:tag_name', requirements: RELEASE_ENDPOINT_REQUIREMENTS do
        authorize_download_code!

        not_found! unless release

        present release, with: Entities::Release, current_user: current_user, include_html_description: params[:include_html_description]
      end

      desc 'Create a new release' do
        detail 'This feature was introduced in GitLab 11.7.'
        named 'create_release'
        success Entities::Release
      end
      params do
        requires :tag_name,    type: String, desc: 'The name of the tag', as: :tag
        optional :name,        type: String, desc: 'The name of the release'
        optional :description, type: String, desc: 'The release notes'
        optional :ref,         type: String, desc: 'The commit sha or branch name'
        optional :assets, type: Hash do
          optional :links, type: Array do
            requires :name, type: String, desc: 'The name of the link'
            requires :url, type: String, desc: 'The URL of the link'
            optional :filepath, type: String, desc: 'The filepath of the link'
            optional :link_type, type: String, desc: 'The link type, one of: "runbook", "image", "package" or "other"'
          end
        end
        optional :milestones, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'The titles of the related milestones', default: []
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
        named 'update_release'
        success Entities::Release
      end
      params do
        requires :tag_name,    type: String, desc: 'The name of the tag', as: :tag
        optional :name,        type: String, desc: 'The name of the release'
        optional :description, type: String, desc: 'Release notes with markdown support'
        optional :released_at, type: DateTime, desc: 'The date when the release will be/was ready.'
        optional :milestones,  type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'The titles of the related milestones'
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
        named 'delete_release'
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
        authorize! :download_code, user_project
      end

      def authorize_create_evidence!
        # extended in EE
      end

      def release
        @release ||= user_project.releases.find_by_tag(params[:tag])
      end

      def log_release_created_audit_event(release)
        # extended in EE
      end

      def log_release_updated_audit_event
        # extended in EE
      end

      def log_release_milestones_updated_audit_event
        # extended in EE
      end

      def release_cli?
        request.env['HTTP_USER_AGENT']&.include?(RELEASE_CLI_USER_AGENT) == true
      end

      def event_context
        {
          release_cli: release_cli?
        }
      end

      def track_release_event
        Gitlab::Tracking.event(options[:for].name, options[:route_options][:named],
          project: user_project, user: current_user, **event_context)
      end
    end
  end
end

API::Releases.prepend_mod_with('API::Releases')
