# frozen_string_literal: true

module API
  class Releases < ::API::Base
    include PaginationParams
    include APIGuard

    allow_access_with_scope :ai_workflows, if: ->(request) { request.get? || request.head? }

    releases_tags = %w[releases]
    RELEASE_ENDPOINT_REQUIREMENTS = ::API::NAMESPACE_OR_PROJECT_REQUIREMENTS
      .merge(tag_name: ::API::NO_SLASH_URL_PART_REGEX)
    RELEASE_CLI_USER_AGENT = 'GitLab-release-cli'

    feature_category :release_orchestration
    urgency :low

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
    end
    resource :groups, requirements: ::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      before { authorize_read_group_releases! }

      desc 'List all releases in a group' do
        detail 'Lists all releases for projects in a specified group.'
        success Entities::Release
        failure [
          { code: 400, message: 'Bad request' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        is_array true
        tags releases_tags
      end
      params do
        requires :id,
          types: [String, Integer],
          desc: 'ID or URL-encoded path of the group.'

        optional :sort,
          type: String,
          values: %w[asc desc],
          default: 'desc',
          desc: 'Sort results in ascending or descending order.'

        optional :simple,
          type: Boolean,
          default: false,
          desc: 'If `true`, only returns limited fields for each release.'

        use :pagination
      end
      route_setting :authorization, permissions: :read_release, boundary_type: :group
      get ":id/releases" do
        finder_options = {
          sort: params[:sort]
        }

        strict_params = declared_params(include_missing: false)
        releases = find_group_releases(finder_options)

        present_group_releases(strict_params, releases)
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'ID or URL-encoded path of the project.'
    end
    resource :projects, requirements: ::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      before { authorize_read_releases! }

      after { track_release_event }

      desc 'List all releases in a project' do
        detail 'Lists all releases for a specified project. Sorted by `released_at`.'
        named 'get_releases'
        is_array true
        success Entities::Release
        tags releases_tags
      end
      params do
        use :pagination

        optional :order_by,
          type: String,
          values: %w[released_at created_at],
          default: 'released_at',
          desc: 'Sort results by the specified field.'

        optional :sort,
          type: String,
          values: %w[asc desc],
          default: 'desc',
          desc: 'Sort results in ascending or descending order.'

        optional :include_html_description,
          type: Boolean,
          desc: 'If `true`, the response includes HTML-rendered Markdown of the release description.'

        optional :updated_before, type: DateTime, desc: 'Return releases updated on or before the specified time.'
        optional :updated_after, type: DateTime, desc: 'Return releases updated on or after the specified time.'
      end
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, permissions: :read_release, boundary_type: :project,
        job_token_policies: :read_releases,
        allow_public_access_for_enabled_project_features: [:repository, :releases]
      get ':id/releases' do
        releases = ::ReleasesFinder.new(user_project, current_user, declared_params.slice(:order_by, :sort, :updated_before, :updated_after)).execute
        include_html_description = declared_params[:include_html_description] == true

        # We cache the serialized payload per user in order to avoid repeated renderings.
        # Since the cached result could contain sensitive information,
        # it will expire in a short interval.
        present_cached paginate(releases),
          with: Entities::Release,
          # `current_user` could be absent if the releases are publicly accesible.
          # We should not use `cache_key` for the user because the version/updated_at
          # context is unnecessary here.
          # The key also carries every option that changes the rendered entity.
          cache_context: ->(_) { "user:{#{current_user&.id}}:include_html_description:#{include_html_description}" },
          expires_in: 5.minutes,
          current_user: current_user,
          include_html_description: include_html_description
      end

      desc 'Retrieve a release by tag name' do
        detail 'Retrieves a release with a specified tag name.'
        named 'get_release'
        success Entities::Release
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags releases_tags
      end
      params do
        requires :tag_name, type: String, desc: 'Git tag the release is associated with.', as: :tag

        optional :include_html_description,
          type: Boolean,
          desc: 'If `true`, the response includes HTML-rendered Markdown of the release description.'
      end
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, permissions: :read_release, boundary_type: :project,
        job_token_policies: :read_releases,
        allow_public_access_for_enabled_project_features: [:repository, :releases]
      get ':id/releases/:tag_name', requirements: RELEASE_ENDPOINT_REQUIREMENTS do
        authorize_read_code!

        not_found! unless release

        present release, with: Entities::Release, current_user: current_user, include_html_description: declared_params[:include_html_description]
      end

      desc 'Download a project release asset file' do
        detail 'This feature was introduced in GitLab 15.4.'
        named 'download_release_asset_file'
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags releases_tags
      end
      params do
        requires :tag_name, type: String, desc: 'Git tag the release is associated with.', as: :tag

        requires :direct_asset_path,
          type: String,
          file_path: true,
          desc: 'The path to the file to download, as specified when creating the release asset',
          as: :filepath
      end
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, permissions: :read_release, boundary_type: :project,
        job_token_policies: :read_releases,
        allow_public_access_for_enabled_project_features: [:repository, :releases]
      get ':id/releases/:tag_name/downloads/*direct_asset_path',
        requirements: RELEASE_ENDPOINT_REQUIREMENTS.merge(::API::NO_FORMAT_SUFFIX_REQUIREMENT) do
        authorize_read_code!

        not_found! unless release

        filepath = declared_params(include_missing: false)[:filepath]
        link = release.links.find_by_filepath!("/#{filepath}")
        not_found! unless link

        redirect link.url
      end

      desc 'Get the latest project release' do
        detail 'This feature was introduced in GitLab 15.4.'
        named 'get_latest_release'
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags releases_tags
      end
      params do
        requires :suffix_path,
          type: String,
          file_path: true,
          desc: 'The path to be suffixed to the latest release'
      end
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, permissions: :read_release, boundary_type: :project,
        job_token_policies: :read_releases,
        allow_public_access_for_enabled_project_features: [:repository, :releases]
      get ':id/releases/permalink/latest(/)(*suffix_path)',
        requirements: RELEASE_ENDPOINT_REQUIREMENTS.merge(::API::NO_FORMAT_SUFFIX_REQUIREMENT) do
        authorize_read_code!

        # Try to find the latest release
        latest_release = find_latest_release
        not_found! unless latest_release

        # Build the full API URL with the tag of the latest release
        redirect_url = api_v4_projects_releases_path(id: user_project.id, tag_name: ERB::Util.url_encode(latest_release.tag))

        # Include the additional suffix_path if present
        redirect_url += "/#{declared_params[:suffix_path]}" if declared_params[:suffix_path].present?

        # Include any query parameter except `order_by` since we have plans to extend it in the future.
        # See https://gitlab.com/gitlab-org/gitlab/-/issues/352945 for reference.
        query_parameters_except_order_by = get_query_params.except('order_by')

        if query_parameters_except_order_by.present?
          redirect_url += "?#{query_parameters_except_order_by.compact.to_param}"
        end

        redirect expose_path(redirect_url)
      end

      desc 'Create a release' do
        detail 'Creates a release. Developer level access to the project is required to create a release.'
        named 'create_release'
        success Entities::Release
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' },
          { code: 409, message: 'Conflict' },
          { code: 422, message: 'Unprocessable entity' }
        ]
        tags releases_tags
      end
      params do
        requires :tag_name,    type: String, desc: 'Tag the release is created from.', as: :tag
        optional :tag_message, type: String, desc: 'Message to use if creating a new annotated tag.'
        optional :name,        type: String, desc: 'Name of the release.'
        optional :description, type: String, desc: 'Description of the release. You can use [Markdown](https://docs.gitlab.com/user/markdown/).'

        optional :ref,
          type: String,
          desc: "If the tag named in `tag_name` doesn't exist, the release is created from this ref and tagged with `tag_name`. Can be a commit SHA, another tag name, or a branch name."

        optional :assets, type: Hash, desc: 'Object that contains assets for the release.' do
          optional :links, type: Array, desc: 'Array of links to include as release assets.' do
            requires :name, type: String, desc: 'Name of the link. Link names must be unique within the release.'
            requires :url, type: String, desc: 'URL of the link. Link URLs must be unique within the release.'
            optional :direct_asset_path, type: String, desc: 'Path for a direct asset link.'
            optional :filepath, type: String, desc: 'Deprecated: optional path for a direct asset link'
            optional :link_type,
              type: String,
              values: ::Releases::Link.link_types.keys,
              default: 'other',
              desc: 'The type of the link.'
          end
        end

        optional :milestones,
          type: Array[String],
          coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce,
          desc: 'Title of each milestone the release is associated with. [GitLab Premium](https://about.gitlab.com/pricing/) customers can specify group milestones. Cannot be combined with the `milestone_ids` parameter.'

        optional :milestone_ids,
          type: Array[String, Integer],
          coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce,
          desc: 'ID of each milestone the release is associated with. GitLab Premium customers can specify group milestones. Cannot be combined with the `milestones` parameter.'

        mutually_exclusive :milestones, :milestone_ids, message: 'Cannot specify milestones and milestone_ids at the same time'

        optional :released_at,
          type: DateTime,
          desc: 'Date and time for the release. Defaults to the current time. Only provide this field when creating an [upcoming](https://docs.gitlab.com/user/project/releases/#upcoming-releases) or [historical](https://docs.gitlab.com/user/project/releases/#historical-releases) release.'

        optional :legacy_catalog_publish,
          type: Boolean,
          desc: 'If `true`, publishes the release to the CI catalog. This parameter is for internal use only and is planned for removal in a future release. If the `ci_release_cli_catalog_publish_option` feature flag is disabled, this parameter is ignored and the release publishes to the CI catalog as before.'
      end
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, permissions: :create_release, boundary_type: :project,
        job_token_policies: :admin_releases
      post ':id/releases' do
        authorize_create_release!

        result = ::Releases::CreateService
          .new(user_project, current_user, declared_params(include_missing: false))
          .execute

        if result[:status] == :success
          present result[:release], with: Entities::Release, current_user: current_user
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end

      desc 'Update a release' do
        detail 'Updates a release. Developer level access to the project is required to update a release.'
        named 'update_release'
        success Entities::Release
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags releases_tags
      end
      params do
        requires :tag_name,    type: String, desc: 'Git tag the release is associated with.', as: :tag
        optional :name,        type: String, desc: 'Name of the release.'
        optional :description, type: String, desc: 'Description of the release. You can use [Markdown](https://docs.gitlab.com/user/markdown/).'
        optional :released_at, type: DateTime, desc: 'Date when the release is or was ready.'

        optional :milestones,
          type: Array[String],
          coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce,
          desc: 'Title of each milestone to associate with the release. [GitLab Premium](https://about.gitlab.com/pricing/) customers can specify group milestones. Cannot be combined with the `milestone_ids` parameter. To remove all milestones from the release, specify `[]`.'

        optional :milestone_ids,
          type: Array[String, Integer],
          coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce,
          desc: 'ID of each milestone the release is associated with. GitLab Premium customers can specify group milestones. Cannot be combined with the `milestones` parameter. To remove all milestones from the release, specify `[]`.'

        mutually_exclusive :milestones, :milestone_ids, message: 'Cannot specify milestones and milestone_ids at the same time'
      end
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, permissions: :update_release, boundary_type: :project,
        job_token_policies: :admin_releases
      put ':id/releases/:tag_name', requirements: RELEASE_ENDPOINT_REQUIREMENTS do
        authorize_update_release!

        result = ::Releases::UpdateService
          .new(user_project, current_user, declared_params(include_missing: false))
          .execute

        if result[:status] == :success
          present result[:release], with: Entities::Release, current_user: current_user
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end

      desc 'Delete a release' do
        detail "Delete a release. Deleting a release doesn't delete the associated tag. Requires at least the Developer role for the project. This feature was introduced in GitLab 11.7."
        named 'delete_release'
        success Entities::Release
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags releases_tags
      end
      params do
        requires :tag_name, type: String, desc: 'Git tag the release is associated with.', as: :tag
      end
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, permissions: :delete_release, boundary_type: :project,
        job_token_policies: :admin_releases
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

    helpers ::API::Helpers::RelatedResourcesHelpers
    helpers do
      def authorize_read_group_releases!
        authorize! :read_release, user_group
      end

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
        @release ||= user_project.releases.find_by_tag(declared_params[:tag])
      end

      def find_latest_release
        ReleasesFinder.new(user_project, current_user, { order_by: 'released_at', sort: 'desc' }).execute.first
      end

      def get_query_params
        return {} unless @request.query_string.present?

        Rack::Utils.parse_nested_query(@request.query_string)
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

      def find_group_releases(finder_options)
        ::Releases::GroupReleasesFinder
          .new(user_group, current_user, finder_options)
          .execute(preload: true)
      end

      def present_group_releases(params, releases)
        options = {
          with: params[:simple] ? Entities::BasicReleaseDetails : Entities::Release,
          current_user: current_user
        }

        # GroupReleasesFinder has already ordered the data for us
        present paginate(releases, skip_default_order: true), **options
      end
    end
  end
end

API::Releases.prepend_mod_with('API::Releases')
