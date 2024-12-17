# frozen_string_literal: true

module API
  class Projects < ::API::Base
    include PaginationParams
    include Helpers::CustomAttributes
    include APIGuard

    helpers Helpers::ProjectsHelpers

    before { authenticate_non_get! }

    allow_access_with_scope :ai_workflows, if: ->(request) { request.get? || request.head? }

    feature_category :groups_and_projects, %w[
      /projects/:id/custom_attributes
      /projects/:id/custom_attributes/:key
      /projects/:id/share_locations
    ]

    PROJECT_ATTACHMENT_SIZE_EXEMPT = 1.gigabyte

    helpers do
      # EE::API::Projects would override this method
      def apply_filters(projects)
        projects = projects.with_statistics if params[:statistics]
        projects = projects.joins(:statistics) if params[:order_by].include?('project_statistics') # rubocop: disable CodeReuse/ActiveRecord
        projects = projects.created_by(current_user).imported.with_import_state if params[:imported]

        lang = params[:with_programming_language]
        projects = projects.with_programming_language(lang) if lang

        projects
      end

      def verify_update_project_attrs!(project, attrs)
        attrs.delete(:repository_storage) unless can?(current_user, :change_repository_storage, project)
      end

      def verify_project_filters!(attrs)
        attrs.delete(:repository_storage) unless can?(current_user, :use_project_statistics_filters)
      end

      def validate_updated_at_order_and_filter!
        return unless filter_by_updated_at? && provided_order_is_not_updated_at?

        # This is necessary as not pairing this filter and ordering will produce an inneficient query
        bad_request!('`updated_at` filter and `updated_at` sorting must be paired')
      end

      def provided_order_is_not_updated_at?
        order_by_param = declared_params[:order_by]

        order_by_param.present? && order_by_param.to_s != 'updated_at'
      end

      def filter_by_updated_at?
        declared_params[:updated_before].present? || declared_params[:updated_after].present?
      end

      def verify_statistics_order_by_projects!
        return unless Helpers::ProjectsHelpers::STATISTICS_SORT_PARAMS.include?(params[:order_by])

        params[:order_by] = if can?(current_user, :use_project_statistics_filters)
                              "project_statistics.#{params[:order_by]}"
                            else
                              route.params['order_by'][:default]
                            end
      end

      def support_order_by_similarity!(attrs)
        return unless params[:order_by] == 'similarity'

        if order_by_similarity?(allow_unauthorized: false)
          # Limit to projects the current user is a member of.
          # Do not include all public projects because it
          # could cause long running queries
          attrs[:non_public] = true
          attrs[:sort] = params['order_by']
        else
          params[:order_by] = route.params['order_by'][:default]
        end
      end

      def delete_project(user_project)
        destroy_conditionally!(user_project) do
          ::Projects::DestroyService.new(user_project, current_user, {}).async_execute
        end

        accepted!
      end

      def validate_projects_api_rate_limit_for_unauthenticated_users!
        check_rate_limit!(:projects_api_rate_limit_unauthenticated, scope: [ip_address]) if current_user.blank?
      end

      def validate_projects_api_rate_limit!
        if current_user && Feature.enabled?(:rate_limit_groups_and_projects_api, current_user)
          check_rate_limit_by_user_or_ip!(:projects_api)
        else
          validate_projects_api_rate_limit_for_unauthenticated_users!
        end
      end
    end

    helpers do
      params :statistics_params do
        optional :statistics, type: Boolean, default: false, desc: 'Include project statistics'
      end

      params :collection_params do
        use :sort_params
        use :filter_params
        use :pagination

        optional :simple, type: Boolean, default: false,
          desc: 'Return only the ID, URL, name, and path of each project'
      end

      params :sort_params do
        optional :order_by, type: String,
          values: %w[id name path created_at updated_at last_activity_at similarity star_count] + Helpers::ProjectsHelpers::STATISTICS_SORT_PARAMS,
          default: 'created_at', desc: "Return projects ordered by field. #{Helpers::ProjectsHelpers::STATISTICS_SORT_PARAMS.join(', ')} are only available to admins. Similarity is available when searching and is limited to projects the user has access to."
        optional :sort, type: String, values: %w[asc desc], default: 'desc',
          desc: 'Return projects sorted in ascending and descending order'
      end

      params :filter_params do
        optional :archived, type: Boolean, desc: 'Limit by archived status'
        optional :visibility, type: String, values: Gitlab::VisibilityLevel.string_values,
          desc: 'Limit by visibility'
        optional :search, type: String, desc: 'Return list of projects matching the search criteria'
        optional :search_namespaces, type: Boolean, desc: "Include ancestor namespaces when matching search criteria"
        optional :owned, type: Boolean, default: false, desc: 'Limit by owned by authenticated user'
        optional :starred, type: Boolean, default: false, desc: 'Limit by starred status'
        optional :imported, type: Boolean, default: false, desc: 'Limit by imported by authenticated user'
        optional :membership, type: Boolean, default: false, desc: 'Limit by projects that the current user is a member of'
        optional :with_issues_enabled, type: Boolean, default: false, desc: 'Limit by enabled issues feature'
        optional :with_merge_requests_enabled, type: Boolean, default: false, desc: 'Limit by enabled merge requests feature'
        optional :with_programming_language, type: String, desc: 'Limit to repositories which use the given programming language'
        optional :min_access_level, type: Integer, values: Gitlab::Access.all_values, desc: 'Limit by minimum access level of authenticated user'
        optional :id_after, type: Integer, desc: 'Limit results to projects with IDs greater than the specified ID'
        optional :id_before, type: Integer, desc: 'Limit results to projects with IDs less than the specified ID'
        optional :last_activity_after, type: DateTime, desc: 'Limit results to projects with last_activity after specified time. Format: ISO 8601 YYYY-MM-DDTHH:MM:SSZ'
        optional :last_activity_before, type: DateTime, desc: 'Limit results to projects with last_activity before specified time. Format: ISO 8601 YYYY-MM-DDTHH:MM:SSZ'
        optional :repository_storage, type: String, desc: 'Which storage shard the repository is on. Available only to admins'
        optional :topic, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'Comma-separated list of topics. Limit results to projects having all topics'
        optional :topic_id, type: Integer, desc: 'Limit results to projects with the assigned topic given by the topic ID'
        optional :updated_before, type: DateTime, desc: 'Return projects updated before the specified datetime. Format: ISO 8601 YYYY-MM-DDTHH:MM:SSZ'
        optional :updated_after, type: DateTime, desc: 'Return projects updated after the specified datetime. Format: ISO 8601 YYYY-MM-DDTHH:MM:SSZ'
        optional :include_pending_delete, type: Boolean, desc: 'Include projects in pending delete state. Can only be set by admins'

        use :optional_filter_params_ee
      end

      params :create_params do
        optional :namespace_id, type: Integer, desc: 'Namespace ID for the new project. Default to the user namespace.'
        optional :import_url, type: String, desc: 'URL from which the project is imported'
        optional :template_name, type: String, desc: "Name of template from which to create project"
        optional :template_project_id, type: Integer, desc: "Project ID of template from which to create project"
        mutually_exclusive :import_url, :template_name, :template_project_id
      end

      def load_projects
        project_params = project_finder_params
        support_order_by_similarity!(project_params)
        verify_project_filters!(project_params)
        ProjectsFinder.new(current_user: current_user, params: project_params).execute
      end

      def present_project(project, options = {})
        options[:with].preload_resource(project) if options[:with].respond_to?(:preload_resource)

        present project, options
      end

      def present_projects(projects, options = {})
        verify_statistics_order_by_projects!

        projects = reorder_projects(projects) unless order_by_similarity?(allow_unauthorized: false)
        projects = apply_filters(projects)

        records, options = paginate_with_strategies(projects, options[:request_scope]) do |projects|
          projects, options = with_custom_attributes(projects, options)

          options = options.reverse_merge(
            with: current_user ? Entities::ProjectWithAccess : Entities::BasicProjectDetails,
            statistics: params[:statistics],
            current_user: current_user,
            license: false
          )
          options[:with] = Entities::BasicProjectDetails if params[:simple]

          [options[:with].prepare_relation(projects, options), options]
        end

        present records, options
      end

      def present_groups(groups)
        options = {
          with: Entities::PublicGroupDetails,
          current_user: current_user
        }

        groups, options = with_custom_attributes(groups, options)

        present paginate(groups), options
      end

      def translate_params_for_compatibility(params)
        params[:builds_enabled] = params.delete(:jobs_enabled) if params.key?(:jobs_enabled)
        params[:emails_enabled] = !params.delete(:emails_disabled) if params.key?(:emails_disabled)
        params[:public_builds] = params.delete(:public_jobs) if params.key?(:public_jobs)

        params
      end

      def add_import_params(params)
        params[:import_type] = 'git' if params[:import_url].present?
        params
      end
    end

    resource :users, requirements: API::USER_REQUIREMENTS do
      desc 'Get a user projects' do
        success code: 200, model: Entities::BasicProjectDetails
        failure [{ code: 404, message: '404 User Not Found' }]
        tags %w[projects]
        is_array true
      end
      params do
        requires :user_id, type: String, desc: 'The ID or username of the user'
        use :collection_params
        use :statistics_params
        use :with_custom_attributes
      end
      get ":user_id/projects", feature_category: :groups_and_projects, urgency: :low do
        if Feature.enabled?(:rate_limit_groups_and_projects_api, current_user)
          check_rate_limit_by_user_or_ip!(:user_projects_api)
        end

        user = find_user(params[:user_id])
        not_found!('User') unless user

        params[:user] = user

        present_projects load_projects
      end

      desc 'Get projects that a user has contributed to' do
        success code: 200, model: Entities::BasicProjectDetails
        failure [{ code: 404, message: '404 User Not Found' }]
        tags %w[projects]
        is_array true
      end
      params do
        requires :user_id, type: String, desc: 'The ID or username of the user'
        use :sort_params
        use :pagination

        optional :simple, type: Boolean, default: false,
          desc: 'Return only the ID, URL, name, and path of each project'
      end
      get ":user_id/contributed_projects", feature_category: :groups_and_projects, urgency: :low do
        if Feature.enabled?(:rate_limit_groups_and_projects_api, current_user)
          check_rate_limit_by_user_or_ip!(:user_contributed_projects_api)
        end

        user = find_user(params[:user_id])
        not_found!('User') unless user

        contributed_projects = ContributedProjectsFinder.new(user: user, current_user: current_user).execute.joined(user)
        present_projects contributed_projects
      end

      desc 'Get projects starred by a user' do
        success code: 200, model: Entities::BasicProjectDetails
        failure [{ code: 404, message: '404 User Not Found' }]
        tags %w[projects]
        is_array true
      end
      params do
        requires :user_id, type: String, desc: 'The ID or username of the user'
        use :collection_params
        use :statistics_params
      end
      get ":user_id/starred_projects", feature_category: :groups_and_projects, urgency: :low do
        if Feature.enabled?(:rate_limit_groups_and_projects_api, current_user)
          check_rate_limit_by_user_or_ip!(:user_starred_projects_api)
        end

        user = find_user(params[:user_id])
        not_found!('User') unless user

        starred_projects = StarredProjectsFinder.new(user, params: project_finder_params, current_user: current_user).execute
        present_projects starred_projects
      end
    end

    resource :projects do
      include CustomAttributesEndpoints

      desc 'Get a list of visible projects for authenticated user' do
        success code: 200, model: Entities::BasicProjectDetails
        failure [
          { code: 400, message: 'Bad request' }
        ]
        tags %w[projects]
        is_array true
      end
      params do
        use :collection_params
        use :statistics_params
        use :with_custom_attributes
      end
      # TODO: Set higher urgency https://gitlab.com/gitlab-org/gitlab/-/issues/211495
      get feature_category: :groups_and_projects, urgency: :low do
        validate_projects_api_rate_limit!
        validate_updated_at_order_and_filter!

        present_projects load_projects
      end

      desc 'Create new project' do
        success code: 201, model: Entities::Project
        failure [
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' },
          { code: 400, message: 'Bad request' }
        ]
        tags %w[projects]
      end
      params do
        optional :name, type: String, desc: 'The name of the project', documentation: { example: 'New Project' }
        optional :path, type: String, desc: 'The path of the repository', documentation: { example: 'new_project' }
        optional :default_branch, type: String, desc: 'The default branch of the project', documentation: { example: 'main' }
        at_least_one_of :name, :path
        use :optional_create_project_params
        use :create_params
      end
      post urgency: :low do
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/issues/21139')
        attrs = declared_params(include_missing: false)
        attrs = translate_params_for_compatibility(attrs)
        attrs = add_import_params(attrs)
        filter_attributes_using_license!(attrs)

        validate_git_import_url!(params[:import_url])

        project = ::Projects::CreateService.new(current_user, attrs).execute

        if project.saved?
          present_project project, with: Entities::Project,
            user_can_admin_project: can?(current_user, :admin_project, project),
            current_user: current_user
        else
          if project.errors[:limit_reached].present?
            error!(project.errors[:limit_reached], 403)
          end

          forbidden! if project.errors[:import_source_disabled].present?

          render_validation_error!(project)
        end
      end

      desc 'Create new project for a specified user. Only available to admin users.' do
        success code: 201, model: Entities::Project
        failure [
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' },
          { code: 400, message: 'Bad request' }
        ]
        tags %w[projects]
      end
      params do
        requires :name, type: String, desc: 'The name of the project', documentation: { example: 'New Project' }
        requires :user_id, type: Integer, desc: 'The ID of a user', documentation: { example: 1 }
        optional :path, type: String, desc: 'The path of the repository', documentation: { example: 'new_project' }
        optional :default_branch, type: String, desc: 'The default branch of the project', documentation: { example: 'main' }
        use :optional_project_params
        use :optional_create_project_params
        use :create_params
      end
      # rubocop: disable CodeReuse/ActiveRecord
      post "user/:user_id", feature_category: :groups_and_projects do
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/issues/21139')
        authenticated_as_admin!
        user = User.find_by(id: params.delete(:user_id))
        not_found!('User') unless user

        attrs = declared_params(include_missing: false)
        attrs = translate_params_for_compatibility(attrs)
        attrs = add_import_params(attrs)
        filter_attributes_using_license!(attrs)
        validate_git_import_url!(params[:import_url])

        project = ::Projects::CreateService.new(user, attrs).execute

        if project.saved?
          present_project project, with: Entities::Project,
            user_can_admin_project: can?(current_user, :admin_project, project),
            current_user: current_user
        else
          forbidden! if project.errors[:import_source_disabled].present?

          render_validation_error!(project)
        end
      end

      desc 'Returns group that can be shared with the given project' do
        success Entities::Group
      end
      params do
        requires :id, type: Integer, desc: 'The id of the project'
        optional :search, type: String, desc: 'Return list of groups matching the search criteria'
      end
      get ':id/share_locations' do
        groups = ::Groups::AcceptingProjectSharesFinder.new(current_user, user_project, declared_params(include_missing: false)).execute

        present_groups groups
      end

      # rubocop: enable CodeReuse/ActiveRecord
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a single project' do
        success code: 200, model: Entities::ProjectWithAccess
        tags %w[projects]
      end
      params do
        use :statistics_params
        use :with_custom_attributes

        optional :license, type: Boolean, default: false,
          desc: 'Include project license data'
      end
      # TODO: Set higher urgency https://gitlab.com/gitlab-org/gitlab/-/issues/357622
      get ":id", feature_category: :groups_and_projects, urgency: :low do
        if Feature.enabled?(:rate_limit_groups_and_projects_api, current_user)
          check_rate_limit_by_user_or_ip!(:project_api)
        end

        options = {
          with: current_user ? Entities::ProjectWithAccess : Entities::ProjectDetails,
          current_user: current_user,
          user_can_admin_project: can?(current_user, :admin_project, user_project),
          statistics: params[:statistics],
          license: params[:license]
        }

        project, options = with_custom_attributes(user_project, options)

        present_project project, options
      end

      desc 'Fork new project for the current user or provided namespace.' do
        success code: 201, model: Entities::Project
        failure [
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' },
          { code: 409, message: 'Conflict' }
        ]
        tags %w[projects]
      end
      params do
        optional :namespace, type: String, desc: '(deprecated) The ID or name of the namespace that the project will be forked into', documentation: { example: 'gitlab' }
        optional :namespace_id, type: Integer, desc: 'The ID of the namespace that the project will be forked into', documentation: { example: 1 }
        optional :namespace_path, type: String, desc: 'The path of the namespace that the project will be forked into', documentation: { example: 'new_path/gitlab' }
        optional :path, type: String, desc: 'The path that will be assigned to the fork', documentation: { example: 'fork' }
        optional :name, type: String, desc: 'The name that will be assigned to the fork', documentation: { example: 'Fork' }
        optional :description, type: String, desc: 'The description that will be assigned to the fork', documentation: { example: 'Description' }
        optional :visibility, type: String, values: Gitlab::VisibilityLevel.string_values, desc: 'The visibility of the fork'
        optional :mr_default_target_self, type: Boolean, desc: 'Merge requests of this forked project targets itself by default'
        optional :branches, type: String, desc: 'Branches to fork'
      end
      post ':id/fork', feature_category: :source_code_management do
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/20759')

        not_found! unless can?(current_user, :fork_project, user_project)

        fork_params = declared_params(include_missing: false)

        fork_params[:namespace] =
          if fork_params[:namespace_id].present?
            find_namespace!(fork_params[:namespace_id])
          elsif fork_params[:namespace_path].present?
            find_namespace_by_path!(fork_params[:namespace_path])
          elsif fork_params[:namespace].present?
            find_namespace!(fork_params[:namespace])
          end

        service = ::Projects::ForkService.new(user_project, current_user, fork_params)

        not_found!('Source Branch') if fork_params[:branches].present? && !service.valid_fork_branch?(fork_params[:branches])
        not_found!('Target Namespace') unless service.valid_fork_target?

        result = service.execute

        if result.success?
          present_project result[:project], {
            with: Entities::Project,
            user_can_admin_project: can?(current_user, :admin_project, result[:project]),
            current_user: current_user
          }
        else
          conflict!(result.message)
        end
      end

      desc 'List forks of this project' do
        success code: 200, model: Entities::Project
        tags %w[projects]
        is_array true
      end
      params do
        use :collection_params
        use :with_custom_attributes
      end
      get ':id/forks', feature_category: :source_code_management, urgency: :low do
        forks = ForkProjectsFinder.new(user_project, params: project_finder_params, current_user: current_user).execute

        present_projects forks, request_scope: user_project
      end

      desc 'Check pages access of this project' do
        success code: 200
        failure [
          { code: 403, message: 'Unauthenticated' }
        ]
        tags %w[projects]
      end
      get ':id/pages_access', urgency: :low, feature_category: :pages do
        authorize! :read_pages_content, user_project unless user_project.public_pages?
        status 200
      end

      desc 'Update an existing project' do
        success code: 200, model: Entities::Project
        failure [
          { code: 400, message: 'Bad request' },
          { code: 403, message: 'Unauthenticated' }
        ]
        tags %w[projects]
      end
      params do
        optional :name, type: String, desc: 'The name of the project', documentation: { example: 'project' }
        optional :default_branch, type: String, desc: 'The default branch of the project', documentation: { example: 'main' }
        optional :path, type: String, desc: 'The path of the repository', documentation: { example: 'group/project' }

        use :optional_project_params
        use :optional_update_params

        at_least_one_of(*Helpers::ProjectsHelpers.update_params_at_least_one_of)
      end
      put ':id', feature_category: :groups_and_projects do
        authorize_admin_project
        attrs = declared_params(include_missing: false)
        authorize! :rename_project, user_project if attrs[:name].present?
        authorize! :change_visibility_level, user_project if user_project.visibility_attribute_present?(attrs)
        authorize! :destroy_pipeline, user_project if attrs.key?(:ci_delete_pipelines_in_seconds)

        attrs = translate_params_for_compatibility(attrs)
        attrs = add_import_params(attrs)
        filter_attributes_using_license!(attrs)
        verify_update_project_attrs!(user_project, attrs)

        user_project.remove_avatar! if attrs.key?(:avatar) && attrs[:avatar].nil?

        result = ::Projects::UpdateService.new(user_project, current_user, attrs).execute

        if result[:status] == :success
          present_project user_project, with: Entities::Project,
            user_can_admin_project: can?(current_user, :admin_project, user_project),
            current_user: current_user
        elsif result[:status] == :api_error
          render_api_error!(result[:message], 400)
        else
          render_validation_error!(user_project)
        end
      end

      desc 'Archive a project' do
        success code: 201, model: Entities::Project
        failure [
          { code: 403, message: 'Unauthenticated' }
        ]
        tags %w[projects]
      end
      post ':id/archive', feature_category: :groups_and_projects do
        authorize!(:archive_project, user_project)

        ::Projects::UpdateService.new(user_project, current_user, archived: true).execute

        present_project user_project, with: Entities::Project, current_user: current_user
      end

      desc 'Unarchive a project' do
        success code: 201, model: Entities::Project
        failure [
          { code: 403, message: 'Unauthenticated' }
        ]
        tags %w[projects]
      end
      post ':id/unarchive', feature_category: :groups_and_projects, urgency: :default do
        authorize!(:archive_project, user_project)

        ::Projects::UpdateService.new(user_project, current_user, archived: false).execute

        present_project user_project, with: Entities::Project, current_user: current_user
      end

      desc 'Star a project' do
        success code: 201, model: Entities::Project
        failure [
          { code: 304, message: 'Not modified' },
          { code: 403, message: 'Unauthenticated' }
        ]
        tags %w[projects]
      end
      post ':id/star', feature_category: :groups_and_projects do
        if current_user.starred?(user_project)
          not_modified!
        else
          current_user.toggle_star(user_project)
          user_project.reset

          present_project user_project, with: Entities::Project, current_user: current_user
        end
      end

      desc 'Unstar a project' do
        success code: 201, model: Entities::Project
        failure [
          { code: 304, message: 'Not modified' },
          { code: 403, message: 'Unauthenticated' }
        ]
        tags %w[projects]
      end
      post ':id/unstar', feature_category: :groups_and_projects do
        if current_user.starred?(user_project)
          current_user.toggle_star(user_project)
          user_project.reset

          present_project user_project, with: Entities::Project, current_user: current_user
        else
          not_modified!
        end
      end

      desc 'Get the users who starred a project' do
        success code: 200, model: Entities::UserBasic
        failure [
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' }
        ]
        is_array true
        tags %w[projects]
      end
      params do
        optional :search, type: String, desc: 'Return list of users matching the search criteria', documentation: { example: 'user' }
        use :pagination
      end
      get ':id/starrers', feature_category: :groups_and_projects do
        starrers = UsersStarProjectsFinder.new(user_project, params, current_user: current_user).execute

        present paginate(starrers), with: Entities::UserStarsProject
      end

      desc 'Get languages in project repository' do
        success code: 200
        failure [
          { code: 404, message: 'Not found' }
        ]
        is_array true
        tags %w[projects]
      end
      get ':id/languages', feature_category: :source_code_management, urgency: :medium do
        ::Projects::RepositoryLanguagesService
          .new(user_project, current_user)
          .execute.to_h { |lang| [lang.name, lang.share] }
      end

      desc 'Delete a project' do
        success code: 202
        failure [
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[projects]
      end
      delete ":id", feature_category: :groups_and_projects do
        authorize! :remove_project, user_project

        delete_project(user_project)
      end

      desc 'Mark this project as forked from another' do
        success code: 201, model: Entities::Project
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[projects]
      end
      params do
        requires :forked_from_id, type: String, desc: 'The ID of the project it was forked from', documentation: { example: 'gitlab' }
      end
      post ":id/fork/:forked_from_id", feature_category: :source_code_management do
        authorize! :link_forked_project, user_project

        fork_from_project = find_project!(params[:forked_from_id])

        not_found!("Source Project") unless fork_from_project

        authorize! :fork_project, fork_from_project

        service = ::Projects::ForkService.new(fork_from_project, current_user)

        unauthorized!('Target Namespace') unless service.valid_fork_target?(user_project.namespace)

        result = service.execute(user_project)

        if result.success?
          present_project user_project.reset, with: Entities::Project, current_user: current_user
        elsif result.reason == :already_forked
          conflict!(result.message)
        else
          render_api_error!(result.message, 400)
        end
      end

      desc 'Remove a forked_from relationship' do
        success code: 204
        failure [
          { code: 304, message: 'Not modified' },
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[projects]
      end
      delete ":id/fork", feature_category: :source_code_management do
        authorize! :remove_fork_project, user_project

        result = destroy_conditionally!(user_project) do
          ::Projects::UnlinkForkService.new(user_project, current_user).execute
        end

        not_modified! unless result
      end

      desc 'Share the project with a group' do
        success code: 201, model: Entities::ProjectGroupLink
        failure [
          { code: 400, message: 'Bad request' },
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[projects]
      end
      params do
        requires :group_id, type: Integer, desc: 'The ID of a group', documentation: { example: 1 }
        requires :group_access, type: Integer, values: Gitlab::Access.all_values, as: :link_group_access, desc: 'The group access level'
        optional :expires_at, type: Date, desc: 'Share expiration date'
        use :share_project_params_ee
      end
      post ":id/share", feature_category: :groups_and_projects, urgency: :low do
        authorize! :admin_project, user_project
        shared_with_group = Group.find_by_id(params[:group_id])

        unless user_project.allowed_to_share_with_group?
          break render_api_error!("The project sharing with group is disabled", 400)
        end

        result = ::Projects::GroupLinks::CreateService
                   .new(user_project, shared_with_group, current_user, declared_params(include_missing: false)).execute

        if result[:status] == :success
          present result[:link], with: Entities::ProjectGroupLink
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end

      desc 'Remove a group share' do
        success code: 204
        failure [
          { code: 400, message: 'Bad request' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[projects]
      end
      params do
        requires :group_id, type: Integer, desc: 'The ID of the group'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      delete ":id/share/:group_id", feature_category: :groups_and_projects do
        authorize! :admin_project, user_project

        link = user_project.project_group_links.find_by(group_id: params[:group_id])
        not_found!('Group Link') unless link

        destroy_conditionally!(link) do
          result = ::Projects::GroupLinks::DestroyService.new(user_project, current_user).execute(link)

          if result.error?
            render_api_error!(result.message, result.reason)
          end
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Import members from another project' do
        detail 'This feature was introduced in GitLab 14.2'
        success code: 200
        failure [
          { code: 403, message: 'Unauthenticated' },
          { code: 403, message: 'Forbidden - Project' },
          { code: 404, message: 'Project Not Found' },
          { code: 422, message: 'Import failed' }
        ]
        tags %w[projects]
      end
      params do
        requires :project_id, type: Integer, desc: 'The ID of the source project to import the members from.'
      end
      post ":id/import_project_members/:project_id", feature_category: :groups_and_projects do
        ::Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/355916')
        authorize! :admin_project, user_project

        source_project = Project.find_by_id(params[:project_id])
        not_found!('Project') unless source_project && can?(current_user, :read_project, source_project)
        forbidden!('Project') unless source_project && can?(current_user, :admin_project_member, source_project)

        result = ::Members::ImportProjectTeamService.new(current_user, params).execute

        if result.success?
          { status: result.status }
        elsif result.reason
          render_structured_api_error!({ 'message' => result.message, 'reason' => result.reason }, :unprocessable_entity)
        else
          { status: result.status, message: result.message, total_members_count: result.payload[:total_members_count] }
        end
      end

      desc 'Get the users list of a project' do
        success code: 200, model: Entities::UserBasic
        failure [
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' }
        ]
        is_array true
        tags %w[projects]
      end
      params do
        optional :search, type: String, desc: 'Return list of users matching the search criteria', documentation: { example: 'user' }
        optional :skip_users, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'Filter out users with the specified IDs'
        use :pagination
      end
      get ':id/users', urgency: :low, feature_category: :system_access do
        users = DeclarativePolicy.subject_scope { user_project.team.users }
        users = users.search(params[:search]) if params[:search].present?
        users = users.where_not_in(params[:skip_users]) if params[:skip_users].present?
        users = users.order('project_authorizations.user_id' => :asc) # rubocop: disable CodeReuse/ActiveRecord

        present paginate(users), with: Entities::UserBasic
      end

      desc 'Get ancestor and shared groups for a project' do
        success code: 200, model: Entities::PublicGroupDetails
        failure [
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' }
        ]
        is_array true
        tags %w[projects]
      end
      params do
        optional :search, type: String, desc: 'Return list of groups matching the search criteria', documentation: { example: 'group' }
        optional :skip_groups, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'Array of group ids to exclude from list'
        optional :with_shared, type: Boolean, default: false,
          desc: 'Include shared groups'
        optional :shared_visible_only, type: Boolean, default: false,
          desc: 'Limit to shared groups user has access to'
        optional :shared_min_access_level, type: Integer, values: Gitlab::Access.all_values,
          desc: 'Limit returned shared groups by minimum access level to the project'
        use :pagination
      end
      get ':id/groups', feature_category: :source_code_management do
        groups = ::Projects::GroupsFinder.new(project: user_project, current_user: current_user, params: declared_params(include_missing: false)).execute
        groups = groups.search(params[:search]) if params[:search].present?

        present_groups groups
      end

      desc 'Get a list of invited groups in this project' do
        success Entities::Group
        is_array true
        tags %w[projects]
      end
      params do
        optional :relation, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, values: %w[direct inherited], desc: 'Filter by group relation'
        optional :search, type: String, desc: 'Search for a specific group'
        optional :min_access_level, type: Integer, values: Gitlab::Access.all_values, desc: 'Limit by minimum access level of authenticated user'

        use :pagination
        use :with_custom_attributes
      end
      get ':id/invited_groups', feature_category: :groups_and_projects do
        check_rate_limit_by_user_or_ip!(:project_invited_groups_api)

        project = find_project!(params[:id])
        groups = ::Namespaces::Projects::InvitedGroupsFinder.new(project, current_user, declared_params).execute
        present_groups groups
      end

      desc 'Start the housekeeping task for a project' do
        detail 'This feature was introduced in GitLab 9.0.'
        success code: 201
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Unauthenticated' },
          { code: 409, message: 'Conflict' }
        ]
        tags %w[projects]
      end
      params do
        optional :task, type: Symbol, default: :eager, values: %i[eager prune], desc: '`prune` to trigger manual prune of unreachable objects or `eager` to trigger eager housekeeping.'
      end
      post ':id/housekeeping', feature_category: :source_code_management do
        authorize_admin_project

        begin
          ::Repositories::HousekeepingService.new(user_project, params[:task]).execute do
            ::Gitlab::Audit::Auditor.audit(
              name: 'manually_trigger_housekeeping',
              author: current_user,
              scope: user_project,
              target: user_project,
              message: "Housekeeping task: #{params[:task]}",
              created_at: DateTime.current
            )
          end
        rescue ::Repositories::HousekeepingService::LeaseTaken => error
          conflict!(error.message)
        end
      end

      desc 'Start a task to recalculate repository size for a project' do
        detail 'This feature was introduced in GitLab 15.0.'
        success code: 201
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Unauthenticated' }
        ]
        tags %w[projects]
      end
      post ':id/repository_size', feature_category: :source_code_management do
        authorize_admin_project

        user_project.repository.expire_statistics_caches

        ::Projects::UpdateStatisticsService.new(user_project, nil, statistics: [:repository_size, :lfs_objects_size]).execute
      end

      desc 'Transfer a project to a new namespace' do
        success code: 200, model: Entities::Project
        failure [
          { code: 400, message: 'Bad request' },
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[projects]
      end
      params do
        requires :namespace, type: String, desc: 'The ID or path of the new namespace', documentation: { example: 'gitlab' }
      end
      put ":id/transfer", feature_category: :groups_and_projects do
        authorize! :change_namespace, user_project

        namespace = find_namespace!(params[:namespace])
        result = ::Projects::TransferService.new(user_project, current_user).execute(namespace)

        if result
          present_project user_project, with: Entities::Project, current_user: current_user
        else
          render_api_error!("Failed to transfer project #{user_project.errors.messages}", 400)
        end
      end

      desc 'Get the namespaces to where the project can be transferred' do
        success code: 200, model: Entities::PublicGroupDetails
        failure [
          { code: 403, message: 'Unauthenticated' }
        ]
        is_array true
        tags %w[projects]
      end
      params do
        optional :search, type: String, desc: 'Return list of namespaces matching the search criteria', documentation: { example: 'search' }
        use :pagination
      end
      get ":id/transfer_locations", feature_category: :groups_and_projects do
        authorize! :change_namespace, user_project
        args = declared_params(include_missing: false)
        args[:permission_scope] = :transfer_projects

        groups = ::Groups::UserGroupsFinder.new(current_user, current_user, args).execute
        groups = groups.excluding_groups(user_project.group).with_route

        present_groups(groups)
      end

      desc 'Show the storage information' do
        success code: 200, model: Entities::ProjectRepositoryStorage
        failure [
          { code: 403, message: 'Unauthenticated' }
        ]
        tags %w[projects]
      end
      params do
        requires :id, type: String, desc: 'ID of a project'
      end
      get ':id/storage', feature_category: :source_code_management do
        authenticated_as_admin!

        present user_project, with: Entities::ProjectRepositoryStorage, current_user: current_user
      end
    end
  end
end

API::Projects.prepend_mod_with('API::Projects')
