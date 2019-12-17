# frozen_string_literal: true

require_dependency 'declarative_policy'

module API
  class Projects < Grape::API
    include PaginationParams
    include Helpers::CustomAttributes

    helpers Helpers::ProjectsHelpers

    before { authenticate_non_get! }

    helpers do
      # EE::API::Projects would override this method
      def apply_filters(projects)
        projects = projects.with_issues_available_for_user(current_user) if params[:with_issues_enabled]
        projects = projects.with_merge_requests_enabled if params[:with_merge_requests_enabled]
        projects = projects.with_statistics if params[:statistics]

        lang = params[:with_programming_language]
        projects = projects.with_programming_language(lang) if lang

        projects
      end

      def verify_update_project_attrs!(project, attrs)
      end

      def delete_project(user_project)
        destroy_conditionally!(user_project) do
          ::Projects::DestroyService.new(user_project, current_user, {}).async_execute
        end

        accepted!
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
        optional :order_by, type: String, values: %w[id name path created_at updated_at last_activity_at],
                            default: 'created_at', desc: 'Return projects ordered by field'
        optional :sort, type: String, values: %w[asc desc], default: 'desc',
                        desc: 'Return projects sorted in ascending and descending order'
      end

      params :filter_params do
        optional :archived, type: Boolean, desc: 'Limit by archived status'
        optional :visibility, type: String, values: Gitlab::VisibilityLevel.string_values,
                              desc: 'Limit by visibility'
        optional :search, type: String, desc: 'Return list of projects matching the search criteria'
        optional :owned, type: Boolean, default: false, desc: 'Limit by owned by authenticated user'
        optional :starred, type: Boolean, default: false, desc: 'Limit by starred status'
        optional :membership, type: Boolean, default: false, desc: 'Limit by projects that the current user is a member of'
        optional :with_issues_enabled, type: Boolean, default: false, desc: 'Limit by enabled issues feature'
        optional :with_merge_requests_enabled, type: Boolean, default: false, desc: 'Limit by enabled merge requests feature'
        optional :with_programming_language, type: String, desc: 'Limit to repositories which use the given programming language'
        optional :min_access_level, type: Integer, values: Gitlab::Access.all_values, desc: 'Limit by minimum access level of authenticated user'
        optional :id_after, type: Integer, desc: 'Limit results to projects with IDs greater than the specified ID'
        optional :id_before, type: Integer, desc: 'Limit results to projects with IDs less than the specified ID'

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
        ProjectsFinder.new(current_user: current_user, params: project_finder_params).execute
      end

      def present_projects(projects, options = {})
        projects = reorder_projects(projects)
        projects = apply_filters(projects)
        projects = paginate(projects)
        projects, options = with_custom_attributes(projects, options)

        options = options.reverse_merge(
          with: current_user ? Entities::ProjectWithAccess : Entities::BasicProjectDetails,
          statistics: params[:statistics],
          current_user: current_user,
          license: false
        )
        options[:with] = Entities::BasicProjectDetails if params[:simple]

        present options[:with].prepare_relation(projects, options), options
      end

      def translate_params_for_compatibility(params)
        params[:builds_enabled] = params.delete(:jobs_enabled) if params.key?(:jobs_enabled)
        params
      end
    end

    resource :users, requirements: API::USER_REQUIREMENTS do
      desc 'Get a user projects' do
        success Entities::BasicProjectDetails
      end
      params do
        requires :user_id, type: String, desc: 'The ID or username of the user'
        use :collection_params
        use :statistics_params
        use :with_custom_attributes
      end
      get ":user_id/projects" do
        user = find_user(params[:user_id])
        not_found!('User') unless user

        params[:user] = user

        present_projects load_projects
      end

      desc 'Get projects starred by a user' do
        success Entities::BasicProjectDetails
      end
      params do
        requires :user_id, type: String, desc: 'The ID or username of the user'
        use :collection_params
        use :statistics_params
      end
      get ":user_id/starred_projects" do
        user = find_user(params[:user_id])
        not_found!('User') unless user

        starred_projects = StarredProjectsFinder.new(user, params: project_finder_params, current_user: current_user).execute
        present_projects starred_projects
      end
    end

    resource :projects do
      include CustomAttributesEndpoints

      desc 'Get a list of visible projects for authenticated user' do
        success Entities::BasicProjectDetails
      end
      params do
        use :collection_params
        use :statistics_params
        use :with_custom_attributes
      end
      get do
        present_projects load_projects
      end

      desc 'Create new project' do
        success Entities::Project
      end
      params do
        optional :name, type: String, desc: 'The name of the project'
        optional :path, type: String, desc: 'The path of the repository'
        at_least_one_of :name, :path
        use :optional_create_project_params
        use :create_params
      end
      post do
        attrs = declared_params(include_missing: false)
        attrs = translate_params_for_compatibility(attrs)
        filter_attributes_using_license!(attrs)
        project = ::Projects::CreateService.new(current_user, attrs).execute

        if project.saved?
          present project, with: Entities::Project,
                           user_can_admin_project: can?(current_user, :admin_project, project),
                           current_user: current_user
        else
          if project.errors[:limit_reached].present?
            error!(project.errors[:limit_reached], 403)
          end

          render_validation_error!(project)
        end
      end

      desc 'Create new project for a specified user. Only available to admin users.' do
        success Entities::Project
      end
      params do
        requires :name, type: String, desc: 'The name of the project'
        requires :user_id, type: Integer, desc: 'The ID of a user'
        optional :path, type: String, desc: 'The path of the repository'
        optional :default_branch, type: String, desc: 'The default branch of the project'
        use :optional_project_params
        use :optional_create_project_params
        use :create_params
      end
      # rubocop: disable CodeReuse/ActiveRecord
      post "user/:user_id" do
        authenticated_as_admin!
        user = User.find_by(id: params.delete(:user_id))
        not_found!('User') unless user

        attrs = declared_params(include_missing: false)
        attrs = translate_params_for_compatibility(attrs)
        filter_attributes_using_license!(attrs)
        project = ::Projects::CreateService.new(user, attrs).execute

        if project.saved?
          present project, with: Entities::Project,
                           user_can_admin_project: can?(current_user, :admin_project, project),
                           current_user: current_user
        else
          render_validation_error!(project)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a single project' do
        success Entities::ProjectWithAccess
      end
      params do
        use :statistics_params
        use :with_custom_attributes

        optional :license, type: Boolean, default: false,
                           desc: 'Include project license data'
      end
      get ":id" do
        options = {
          with: current_user ? Entities::ProjectWithAccess : Entities::BasicProjectDetails,
          current_user: current_user,
          user_can_admin_project: can?(current_user, :admin_project, user_project),
          statistics: params[:statistics],
          license: params[:license]
        }

        project, options = with_custom_attributes(user_project, options)

        present project, options
      end

      desc 'Fork new project for the current user or provided namespace.' do
        success Entities::Project
      end
      params do
        optional :namespace, type: String, desc: 'The ID or name of the namespace that the project will be forked into'
        optional :path, type: String, desc: 'The path that will be assigned to the fork'
        optional :name, type: String, desc: 'The name that will be assigned to the fork'
      end
      post ':id/fork' do
        Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-foss/issues/42284')

        fork_params = declared_params(include_missing: false)
        namespace_id = fork_params[:namespace]

        if namespace_id.present?
          fork_params[:namespace] = find_namespace(namespace_id)

          unless fork_params[:namespace] && can?(current_user, :create_projects, fork_params[:namespace])
            not_found!('Target Namespace')
          end
        end

        forked_project = ::Projects::ForkService.new(user_project, current_user, fork_params).execute

        if forked_project.errors.any?
          conflict!(forked_project.errors.messages)
        else
          present forked_project, with: Entities::Project,
                                  user_can_admin_project: can?(current_user, :admin_project, forked_project),
                                  current_user: current_user
        end
      end

      desc 'List forks of this project' do
        success Entities::Project
      end
      params do
        use :collection_params
        use :with_custom_attributes
      end
      get ':id/forks' do
        forks = ForkProjectsFinder.new(user_project, params: project_finder_params, current_user: current_user).execute

        present_projects forks
      end

      desc 'Check pages access of this project'
      get ':id/pages_access' do
        authorize! :read_pages_content, user_project unless user_project.public_pages?
        status 200
      end

      desc 'Update an existing project' do
        success Entities::Project
      end
      params do
        optional :name, type: String, desc: 'The name of the project'
        optional :default_branch, type: String, desc: 'The default branch of the project'
        optional :path, type: String, desc: 'The path of the repository'

        use :optional_project_params
        use :optional_update_params_ee

        at_least_one_of(*Helpers::ProjectsHelpers.update_params_at_least_one_of)
      end
      put ':id' do
        authorize_admin_project
        attrs = declared_params(include_missing: false)
        authorize! :rename_project, user_project if attrs[:name].present?
        authorize! :change_visibility_level, user_project if attrs[:visibility].present?

        attrs = translate_params_for_compatibility(attrs)
        filter_attributes_using_license!(attrs)
        verify_update_project_attrs!(user_project, attrs)

        result = ::Projects::UpdateService.new(user_project, current_user, attrs).execute

        if result[:status] == :success
          present user_project, with: Entities::Project,
                                user_can_admin_project: can?(current_user, :admin_project, user_project),
                                current_user: current_user
        else
          render_validation_error!(user_project)
        end
      end

      desc 'Archive a project' do
        success Entities::Project
      end
      post ':id/archive' do
        authorize!(:archive_project, user_project)

        ::Projects::UpdateService.new(user_project, current_user, archived: true).execute

        present user_project, with: Entities::Project, current_user: current_user
      end

      desc 'Unarchive a project' do
        success Entities::Project
      end
      post ':id/unarchive' do
        authorize!(:archive_project, user_project)

        ::Projects::UpdateService.new(@project, current_user, archived: false).execute

        present user_project, with: Entities::Project, current_user: current_user
      end

      desc 'Star a project' do
        success Entities::Project
      end
      post ':id/star' do
        if current_user.starred?(user_project)
          not_modified!
        else
          current_user.toggle_star(user_project)
          user_project.reset

          present user_project, with: Entities::Project, current_user: current_user
        end
      end

      desc 'Unstar a project' do
        success Entities::Project
      end
      post ':id/unstar' do
        if current_user.starred?(user_project)
          current_user.toggle_star(user_project)
          user_project.reset

          present user_project, with: Entities::Project, current_user: current_user
        else
          not_modified!
        end
      end

      desc 'Get the users who starred a project' do
        success Entities::UserBasic
      end
      params do
        optional :search, type: String, desc: 'Return list of users matching the search criteria'
        use :pagination
      end
      get ':id/starrers' do
        starrers = UsersStarProjectsFinder.new(user_project, params, current_user: current_user).execute

        present paginate(starrers), with: Entities::UserStarsProject
      end

      desc 'Get languages in project repository'
      get ':id/languages' do
        ::Projects::RepositoryLanguagesService
          .new(user_project, current_user)
          .execute.map { |lang| [lang.name, lang.share] }.to_h
      end

      desc 'Remove a project'
      delete ":id" do
        authorize! :remove_project, user_project

        delete_project(user_project)
      end

      desc 'Mark this project as forked from another'
      params do
        requires :forked_from_id, type: String, desc: 'The ID of the project it was forked from'
      end
      post ":id/fork/:forked_from_id" do
        authorize! :admin_project, user_project

        fork_from_project = find_project!(params[:forked_from_id])

        not_found!("Source Project") unless fork_from_project

        result = ::Projects::ForkService.new(fork_from_project, current_user).execute(user_project)

        if result
          present user_project.reset, with: Entities::Project, current_user: current_user
        else
          render_api_error!("Project already forked", 409) if user_project.forked?
        end
      end

      desc 'Remove a forked_from relationship'
      delete ":id/fork" do
        authorize! :remove_fork_project, user_project

        result = destroy_conditionally!(user_project) do
          ::Projects::UnlinkForkService.new(user_project, current_user).execute
        end

        result ? status(204) : not_modified!
      end

      desc 'Share the project with a group' do
        success Entities::ProjectGroupLink
      end
      params do
        requires :group_id, type: Integer, desc: 'The ID of a group'
        requires :group_access, type: Integer, values: Gitlab::Access.values, as: :link_group_access, desc: 'The group access level'
        optional :expires_at, type: Date, desc: 'Share expiration date'
      end
      post ":id/share" do
        authorize! :admin_project, user_project
        group = Group.find_by_id(params[:group_id])

        unless user_project.allowed_to_share_with_group?
          break render_api_error!("The project sharing with group is disabled", 400)
        end

        result = ::Projects::GroupLinks::CreateService.new(user_project, current_user, declared_params(include_missing: false))
          .execute(group)

        if result[:status] == :success
          present result[:link], with: Entities::ProjectGroupLink
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end

      params do
        requires :group_id, type: Integer, desc: 'The ID of the group'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      delete ":id/share/:group_id" do
        authorize! :admin_project, user_project

        link = user_project.project_group_links.find_by(group_id: params[:group_id])
        not_found!('Group Link') unless link

        destroy_conditionally!(link)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Upload a file'
      params do
        # TODO: remove rubocop disable - https://gitlab.com/gitlab-org/gitlab/issues/14960
        requires :file, type: File, desc: 'The file to be uploaded' # rubocop:disable Scalability/FileUploads
      end
      post ":id/uploads" do
        UploadService.new(user_project, params[:file]).execute.to_h
      end

      desc 'Get the users list of a project' do
        success Entities::UserBasic
      end
      params do
        optional :search, type: String, desc: 'Return list of users matching the search criteria'
        optional :skip_users, type: Array[Integer], desc: 'Filter out users with the specified IDs'
        use :pagination
      end
      get ':id/users' do
        users = DeclarativePolicy.subject_scope { user_project.team.users }
        users = users.search(params[:search]) if params[:search].present?
        users = users.where_not_in(params[:skip_users]) if params[:skip_users].present?

        present paginate(users), with: Entities::UserBasic
      end

      desc 'Start the housekeeping task for a project' do
        detail 'This feature was introduced in GitLab 9.0.'
      end
      post ':id/housekeeping' do
        authorize_admin_project

        begin
          ::Projects::HousekeepingService.new(user_project, :gc).execute
        rescue ::Projects::HousekeepingService::LeaseTaken => error
          conflict!(error.message)
        end
      end

      desc 'Transfer a project to a new namespace'
      params do
        requires :namespace, type: String, desc: 'The ID or path of the new namespace'
      end
      put ":id/transfer" do
        authorize! :change_namespace, user_project

        namespace = find_namespace!(params[:namespace])
        result = ::Projects::TransferService.new(user_project, current_user).execute(namespace)

        if result
          present user_project, with: Entities::Project, current_user: current_user
        else
          render_api_error!("Failed to transfer project #{user_project.errors.messages}", 400)
        end
      end
    end
  end
end

API::Projects.prepend_if_ee('EE::API::Projects')
