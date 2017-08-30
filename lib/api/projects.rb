require_dependency 'declarative_policy'

module API
  # Projects API
  class Projects < Grape::API
    include PaginationParams

    before { authenticate_non_get! }

    helpers do
      params :optional_params_ce do
        optional :description, type: String, desc: 'The description of the project'
        optional :ci_config_path, type: String, desc: 'The path to CI config file. Defaults to `.gitlab-ci.yml`'
        optional :issues_enabled, type: Boolean, desc: 'Flag indication if the issue tracker is enabled'
        optional :merge_requests_enabled, type: Boolean, desc: 'Flag indication if merge requests are enabled'
        optional :wiki_enabled, type: Boolean, desc: 'Flag indication if the wiki is enabled'
        optional :jobs_enabled, type: Boolean, desc: 'Flag indication if jobs are enabled'
        optional :snippets_enabled, type: Boolean, desc: 'Flag indication if snippets are enabled'
        optional :shared_runners_enabled, type: Boolean, desc: 'Flag indication if shared runners are enabled for that project'
        optional :container_registry_enabled, type: Boolean, desc: 'Flag indication if the container registry is enabled for that project'
        optional :lfs_enabled, type: Boolean, desc: 'Flag indication if Git LFS is enabled for that project'
        optional :visibility, type: String, values: Gitlab::VisibilityLevel.string_values, desc: 'The visibility of the project.'
        optional :public_builds, type: Boolean, desc: 'Perform public builds'
        optional :request_access_enabled, type: Boolean, desc: 'Allow users to request member access'
        optional :only_allow_merge_if_pipeline_succeeds, type: Boolean, desc: 'Only allow to merge if builds succeed'
        optional :only_allow_merge_if_all_discussions_are_resolved, type: Boolean, desc: 'Only allow to merge if all discussions are resolved'
        optional :tag_list, type: Array[String], desc: 'The list of tags for a project'
        optional :avatar, type: File, desc: 'Avatar image for project'
        optional :printing_merge_request_link_enabled, type: Boolean, desc: 'Show link to create/view merge request when pushing from the command line'
      end

      params :optional_params_ee do
        optional :repository_storage, type: String, desc: 'Which storage shard the repository is on. Available only to admins'
        optional :approvals_before_merge, type: Integer, desc: 'How many approvers should approve merge request by default'
      end

      params :optional_params do
        use :optional_params_ce
        use :optional_params_ee
      end

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
        optional :archived, type: Boolean, default: false, desc: 'Limit by archived status'
        optional :visibility, type: String, values: Gitlab::VisibilityLevel.string_values,
                              desc: 'Limit by visibility'
        optional :search, type: String, desc: 'Return list of projects matching the search criteria'
        optional :owned, type: Boolean, default: false, desc: 'Limit by owned by authenticated user'
        optional :starred, type: Boolean, default: false, desc: 'Limit by starred status'
        optional :membership, type: Boolean, default: false, desc: 'Limit by projects that the current user is a member of'
        optional :with_issues_enabled, type: Boolean, default: false, desc: 'Limit by enabled issues feature'
        optional :with_merge_requests_enabled, type: Boolean, default: false, desc: 'Limit by enabled merge requests feature'
      end

      params :create_params do
        optional :namespace_id, type: Integer, desc: 'Namespace ID for the new project. Default to the user namespace.'
        optional :import_url, type: String, desc: 'URL from which the project is imported'
      end

      def present_projects(options = {})
        projects = ProjectsFinder.new(current_user: current_user, params: project_finder_params).execute
        projects = reorder_projects(projects)
        projects = projects.with_statistics if params[:statistics]
        projects = projects.with_issues_enabled if params[:with_issues_enabled]
        projects = projects.with_merge_requests_enabled if params[:with_merge_requests_enabled]

        if current_user
          projects = projects.includes(:route, :taggings, namespace: :route)
          project_members = current_user.project_members
          group_members = current_user.group_members
        end

        options = options.reverse_merge(
          with: current_user ? Entities::ProjectWithAccess : Entities::BasicProjectDetails,
          statistics: params[:statistics],
          project_members: project_members,
          group_members: group_members,
          current_user: current_user
        )
        options[:with] = Entities::BasicProjectDetails if params[:simple]

        present paginate(projects), options
      end
    end

    resource :users, requirements: { user_id: %r{[^/]+} } do
      desc 'Get a user projects' do
        success Entities::BasicProjectDetails
      end
      params do
        requires :user_id, type: String, desc: 'The ID or username of the user'
        use :collection_params
        use :statistics_params
      end
      get ":user_id/projects" do
        user = find_user(params[:user_id])
        not_found!('User') unless user

        params[:user] = user

        present_projects
      end
    end

    resource :projects do
      desc 'Get a list of visible projects for authenticated user' do
        success Entities::BasicProjectDetails
      end
      params do
        use :collection_params
        use :statistics_params
      end
      get do
        present_projects
      end

      desc 'Create new project' do
        success Entities::Project
      end
      params do
        optional :name, type: String, desc: 'The name of the project'
        optional :path, type: String, desc: 'The path of the repository'
        at_least_one_of :name, :path
        use :optional_params
        use :create_params
      end
      post do
        attrs = declared_params(include_missing: false)
        attrs[:builds_enabled] = attrs.delete(:jobs_enabled) if attrs.key?(:jobs_enabled)
        project = ::Projects::CreateService.new(current_user, attrs).execute

        if project.saved?
          present project, with: Entities::Project,
                           user_can_admin_project: can?(current_user, :admin_project, project)
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
        use :optional_params
        use :create_params
      end
      post "user/:user_id" do
        authenticated_as_admin!
        user = User.find_by(id: params.delete(:user_id))
        not_found!('User') unless user

        attrs = declared_params(include_missing: false)
        project = ::Projects::CreateService.new(user, attrs).execute

        if project.saved?
          present project, with: Entities::Project,
                           user_can_admin_project: can?(current_user, :admin_project, project)
        else
          render_validation_error!(project)
        end
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: { id: %r{[^/]+} } do
      desc 'Get a single project' do
        success Entities::ProjectWithAccess
      end
      params do
        use :statistics_params
      end
      get ":id" do
        entity = current_user ? Entities::ProjectWithAccess : Entities::BasicProjectDetails
        present user_project, with: entity, current_user: current_user,
                              user_can_admin_project: can?(current_user, :admin_project, user_project), statistics: params[:statistics]
      end

      desc 'Fork new project for the current user or provided namespace.' do
        success Entities::Project
      end
      params do
        optional :namespace, type: String, desc: 'The ID or name of the namespace that the project will be forked into'
      end
      post ':id/fork' do
        fork_params = declared_params(include_missing: false)
        namespace_id = fork_params[:namespace]

        if namespace_id.present?
          fork_params[:namespace] = if namespace_id =~ /^\d+$/
                                      Namespace.find_by(id: namespace_id)
                                    else
                                      Namespace.find_by_path_or_name(namespace_id)
                                    end

          unless fork_params[:namespace] && can?(current_user, :create_projects, fork_params[:namespace])
            not_found!('Target Namespace')
          end
        end

        forked_project = ::Projects::ForkService.new(user_project, current_user, fork_params).execute

        if forked_project.errors.any?
          conflict!(forked_project.errors.messages)
        else
          present forked_project, with: Entities::Project,
                                  user_can_admin_project: can?(current_user, :admin_project, forked_project)
        end
      end

      desc 'Update an existing project' do
        success Entities::Project
      end
      params do
        # CE
        at_least_one_of_ce =
          [
            :jobs_enabled,
            :container_registry_enabled,
            :default_branch,
            :description,
            :issues_enabled,
            :lfs_enabled,
            :merge_requests_enabled,
            :name,
            :only_allow_merge_if_all_discussions_are_resolved,
            :only_allow_merge_if_pipeline_succeeds,
            :path,
            :printing_merge_request_link_enabled,
            :public_builds,
            :request_access_enabled,
            :shared_runners_enabled,
            :snippets_enabled,
            :tag_list,
            :visibility,
            :wiki_enabled
          ]
        optional :name, type: String, desc: 'The name of the project'
        optional :default_branch, type: String, desc: 'The default branch of the project'
        optional :path, type: String, desc: 'The path of the repository'

        # EE
        at_least_one_of_ee = [
          :approvals_before_merge,
          :repository_storage
        ]

        use :optional_params
        at_least_one_of(*(at_least_one_of_ce + at_least_one_of_ee))
      end
      put ':id' do
        authorize_admin_project
        attrs = declared_params(include_missing: false)
        authorize! :rename_project, user_project if attrs[:name].present?
        authorize! :change_visibility_level, user_project if attrs[:visibility].present?

        attrs[:builds_enabled] = attrs.delete(:jobs_enabled) if attrs.key?(:jobs_enabled)

        result = ::Projects::UpdateService.new(user_project, current_user, attrs).execute

        if result[:status] == :success
          present user_project, with: Entities::Project,
                                user_can_admin_project: can?(current_user, :admin_project, user_project)
        else
          render_validation_error!(user_project)
        end
      end

      desc 'Archive a project' do
        success Entities::Project
      end
      post ':id/archive' do
        authorize!(:archive_project, user_project)

        user_project.archive!

        present user_project, with: Entities::Project
      end

      desc 'Unarchive a project' do
        success Entities::Project
      end
      post ':id/unarchive' do
        authorize!(:archive_project, user_project)

        user_project.unarchive!

        present user_project, with: Entities::Project
      end

      desc 'Star a project' do
        success Entities::Project
      end
      post ':id/star' do
        if current_user.starred?(user_project)
          not_modified!
        else
          current_user.toggle_star(user_project)
          user_project.reload

          present user_project, with: Entities::Project
        end
      end

      desc 'Unstar a project' do
        success Entities::Project
      end
      post ':id/unstar' do
        if current_user.starred?(user_project)
          current_user.toggle_star(user_project)
          user_project.reload

          present user_project, with: Entities::Project
        else
          not_modified!
        end
      end

      desc 'Remove a project'
      delete ":id" do
        authorize! :remove_project, user_project
        ::Projects::DestroyService.new(user_project, current_user, {}).async_execute

        accepted!
      end

      desc 'Mark this project as forked from another'
      params do
        requires :forked_from_id, type: String, desc: 'The ID of the project it was forked from'
      end
      post ":id/fork/:forked_from_id" do
        authenticated_as_admin!

        forked_from_project = find_project!(params[:forked_from_id])
        not_found!("Source Project") unless forked_from_project

        if user_project.forked_from_project.nil?
          user_project.create_forked_project_link(forked_to_project_id: user_project.id, forked_from_project_id: forked_from_project.id)

          ::Projects::ForksCountService.new(forked_from_project).refresh_cache
        else
          render_api_error!("Project already forked", 409)
        end
      end

      desc 'Remove a forked_from relationship'
      delete ":id/fork" do
        authorize! :remove_fork_project, user_project

        if user_project.forked?
          status 204
          user_project.forked_project_link.destroy
        else
          not_modified!
        end
      end

      desc 'Share the project with a group' do
        success Entities::ProjectGroupLink
      end
      params do
        requires :group_id, type: Integer, desc: 'The ID of a group'
        requires :group_access, type: Integer, values: Gitlab::Access.values, desc: 'The group access level'
        optional :expires_at, type: Date, desc: 'Share expiration date'
      end
      post ":id/share" do
        authorize! :admin_project, user_project
        group = Group.find_by_id(params[:group_id])

        unless group && can?(current_user, :read_group, group)
          not_found!('Group')
        end

        unless user_project.allowed_to_share_with_group?
          return render_api_error!("The project sharing with group is disabled", 400)
        end

        link = user_project.project_group_links.new(declared_params(include_missing: false))

        if link.save
          present link, with: Entities::ProjectGroupLink
        else
          render_api_error!(link.errors.full_messages.first, 409)
        end
      end

      params do
        requires :group_id, type: Integer, desc: 'The ID of the group'
      end
      delete ":id/share/:group_id" do
        authorize! :admin_project, user_project

        link = user_project.project_group_links.find_by(group_id: params[:group_id])
        not_found!('Group Link') unless link

        status 204
        link.destroy
      end

      desc 'Upload a file'
      params do
        requires :file, type: File, desc: 'The file to be uploaded'
      end
      post ":id/uploads" do
        UploadService.new(user_project, params[:file]).execute
      end

      desc 'Get the users list of a project' do
        success Entities::UserBasic
      end
      params do
        optional :search, type: String, desc: 'Return list of users matching the search criteria'
        use :pagination
      end
      get ':id/users' do
        users = DeclarativePolicy.subject_scope { user_project.team.users }
        users = users.search(params[:search]) if params[:search].present?

        present paginate(users), with: Entities::UserBasic
      end

      desc 'Start the housekeeping task for a project' do
        detail 'This feature was introduced in GitLab 9.0.'
      end
      post ':id/housekeeping' do
        authorize_admin_project

        begin
          ::Projects::HousekeepingService.new(user_project).execute
        rescue ::Projects::HousekeepingService::LeaseTaken => error
          conflict!(error.message)
        end
      end
    end
  end
end
