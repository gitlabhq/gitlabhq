module API
  module V3
    class Projects < Grape::API
      include PaginationParams

      before { authenticate_non_get! }

      after_validation do
        set_only_allow_merge_if_pipeline_succeeds!
      end

      helpers do
        params :optional_params do
          optional :description, type: String, desc: 'The description of the project'
          optional :issues_enabled, type: Boolean, desc: 'Flag indication if the issue tracker is enabled'
          optional :merge_requests_enabled, type: Boolean, desc: 'Flag indication if merge requests are enabled'
          optional :wiki_enabled, type: Boolean, desc: 'Flag indication if the wiki is enabled'
          optional :builds_enabled, type: Boolean, desc: 'Flag indication if builds are enabled'
          optional :snippets_enabled, type: Boolean, desc: 'Flag indication if snippets are enabled'
          optional :shared_runners_enabled, type: Boolean, desc: 'Flag indication if shared runners are enabled for that project'
          optional :resolve_outdated_diff_discussions, type: Boolean, desc: 'Automatically resolve merge request diffs discussions on lines changed with a push'
          optional :container_registry_enabled, type: Boolean, desc: 'Flag indication if the container registry is enabled for that project'
          optional :lfs_enabled, type: Boolean, desc: 'Flag indication if Git LFS is enabled for that project'
          optional :public, type: Boolean, desc: 'Create a public project. The same as visibility_level = 20.'
          optional :visibility_level, type: Integer, values: [
            Gitlab::VisibilityLevel::PRIVATE,
            Gitlab::VisibilityLevel::INTERNAL,
            Gitlab::VisibilityLevel::PUBLIC
          ], desc: 'Create a public project. The same as visibility_level = 20.'
          optional :public_builds, type: Boolean, desc: 'Perform public builds'
          optional :request_access_enabled, type: Boolean, desc: 'Allow users to request member access'
          optional :only_allow_merge_if_build_succeeds, type: Boolean, desc: 'Only allow to merge if builds succeed'
          optional :only_allow_merge_if_pipeline_succeeds, type: Boolean, desc: 'Only allow to merge if builds succeed'
          optional :only_allow_merge_if_all_discussions_are_resolved, type: Boolean, desc: 'Only allow to merge if all discussions are resolved'

          # EE-specific
          optional :repository_storage, type: String, desc: 'Which storage shard the repository is on. Available only to admins'
          optional :approvals_before_merge, type: Integer, desc: 'How many approvers should approve merge request by default'
        end

        def map_public_to_visibility_level(attrs)
          publik = attrs.delete(:public)
          if !publik.nil? && !attrs[:visibility_level].present?
            # Since setting the public attribute to private could mean either
            # private or internal, use the more conservative option, private.
            attrs[:visibility_level] = (publik == true) ? Gitlab::VisibilityLevel::PUBLIC : Gitlab::VisibilityLevel::PRIVATE
          end

          attrs
        end

        def set_only_allow_merge_if_pipeline_succeeds!
          if params.key?(:only_allow_merge_if_build_succeeds)
            params[:only_allow_merge_if_pipeline_succeeds] = params.delete(:only_allow_merge_if_build_succeeds)
          end
        end
      end

      resource :projects do
        helpers do
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
            optional :archived, type: Boolean, default: nil, desc: 'Limit by archived status'
            optional :visibility, type: String, values: %w[public internal private],
                                  desc: 'Limit by visibility'
            optional :search, type: String, desc: 'Return list of authorized projects matching the search criteria'
          end

          params :statistics_params do
            optional :statistics, type: Boolean, default: false, desc: 'Include project statistics'
          end

          params :create_params do
            optional :namespace_id, type: Integer, desc: 'Namespace ID for the new project. Default to the user namespace.'
            optional :import_url, type: String, desc: 'URL from which the project is imported'
          end

          def present_projects(projects, options = {})
            options = options.reverse_merge(
              with: ::API::V3::Entities::Project,
              current_user: current_user,
              simple: params[:simple]
            )

            projects = filter_projects(projects)
            projects = projects.with_statistics if options[:statistics]
            options[:with] = ::API::Entities::BasicProjectDetails if options[:simple]

            present paginate(projects), options
          end
        end

        desc 'Get a list of visible projects for authenticated user' do
          success ::API::Entities::BasicProjectDetails
        end
        params do
          use :collection_params
        end
        get '/visible' do
          entity = current_user ? ::API::V3::Entities::ProjectWithAccess : ::API::Entities::BasicProjectDetails
          present_projects ProjectsFinder.new(current_user: current_user).execute, with: entity
        end

        desc 'Get a projects list for authenticated user' do
          success ::API::Entities::BasicProjectDetails
        end
        params do
          use :collection_params
        end
        get do
          authenticate!

          present_projects current_user.authorized_projects.order_id_desc,
            with: ::API::V3::Entities::ProjectWithAccess
        end

        desc 'Get an owned projects list for authenticated user' do
          success ::API::Entities::BasicProjectDetails
        end
        params do
          use :collection_params
          use :statistics_params
        end
        get '/owned' do
          authenticate!

          present_projects current_user.owned_projects,
            with: ::API::V3::Entities::ProjectWithAccess,
            statistics: params[:statistics]
        end

        desc 'Gets starred project for the authenticated user' do
          success ::API::Entities::BasicProjectDetails
        end
        params do
          use :collection_params
        end
        get '/starred' do
          authenticate!

          present_projects ProjectsFinder.new(current_user: current_user, params: { starred: true }).execute
        end

        desc 'Get all projects for admin user' do
          success ::API::Entities::BasicProjectDetails
        end
        params do
          use :collection_params
          use :statistics_params
        end
        get '/all' do
          authenticated_as_admin!

          present_projects Project.all, with: ::API::V3::Entities::ProjectWithAccess, statistics: params[:statistics]
        end

        desc 'Search for projects the current user has access to' do
          success ::API::V3::Entities::Project
        end
        params do
          requires :query, type: String, desc: 'The project name to be searched'
          use :sort_params
          use :pagination
        end
        get "/search/:query", requirements: { query: %r{[^/]+} } do
          search_service = ::Search::GlobalService.new(current_user, search: params[:query]).execute
          projects = search_service.objects('projects', params[:page], false)
          projects = projects.reorder(params[:order_by] => params[:sort])

          present paginate(projects), with: ::API::V3::Entities::Project
        end

        desc 'Create new project' do
          success ::API::V3::Entities::Project
        end
        params do
          optional :name, type: String, desc: 'The name of the project'
          optional :path, type: String, desc: 'The path of the repository'
          at_least_one_of :name, :path
          use :optional_params
          use :create_params
        end
        post do
          attrs = map_public_to_visibility_level(declared_params(include_missing: false))
          project = ::Projects::CreateService.new(current_user, attrs).execute

          if project.saved?
            present project, with: ::API::V3::Entities::Project,
                             user_can_admin_project: can?(current_user, :admin_project, project)
          else
            if project.errors[:limit_reached].present?
              error!(project.errors[:limit_reached], 403)
            end

            render_validation_error!(project)
          end
        end

        desc 'Create new project for a specified user. Only available to admin users.' do
          success ::API::V3::Entities::Project
        end
        params do
          requires :name, type: String, desc: 'The name of the project'
          requires :user_id, type: Integer, desc: 'The ID of a user'
          optional :default_branch, type: String, desc: 'The default branch of the project'
          use :optional_params
          use :create_params
        end
        post "user/:user_id" do
          authenticated_as_admin!
          user = User.find_by(id: params.delete(:user_id))
          not_found!('User') unless user

          attrs = map_public_to_visibility_level(declared_params(include_missing: false))
          project = ::Projects::CreateService.new(user, attrs).execute

          if project.saved?
            present project, with: ::API::V3::Entities::Project,
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
          success ::API::V3::Entities::ProjectWithAccess
        end
        get ":id" do
          entity = current_user ? ::API::V3::Entities::ProjectWithAccess : ::API::Entities::BasicProjectDetails
          present user_project, with: entity, current_user: current_user,
                                user_can_admin_project: can?(current_user, :admin_project, user_project)
        end

        desc 'Get events for a single project' do
          success ::API::V3::Entities::Event
        end
        params do
          use :pagination
        end
        get ":id/events" do
          present paginate(user_project.events.recent), with: ::API::V3::Entities::Event
        end

        desc 'Fork new project for the current user or provided namespace.' do
          success ::API::V3::Entities::Project
        end
        params do
          optional :namespace, type: String, desc: 'The ID or name of the namespace that the project will be forked into'
        end
        post 'fork/:id' do
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
            present forked_project, with: ::API::V3::Entities::Project,
                                    user_can_admin_project: can?(current_user, :admin_project, forked_project)
          end
        end

        desc 'Update an existing project' do
          success ::API::V3::Entities::Project
        end
        params do
          optional :name, type: String, desc: 'The name of the project'
          optional :default_branch, type: String, desc: 'The default branch of the project'
          optional :path, type: String, desc: 'The path of the repository'
          use :optional_params
          at_least_one_of :name, :description, :issues_enabled, :merge_requests_enabled,
            :wiki_enabled, :builds_enabled, :snippets_enabled,
            :shared_runners_enabled, :resolve_outdated_diff_discussions,
            :container_registry_enabled, :lfs_enabled, :public, :visibility_level,
            :public_builds, :request_access_enabled, :only_allow_merge_if_build_succeeds,
            :only_allow_merge_if_all_discussions_are_resolved, :path,
            :default_branch,
            ## EE-specific
            :repository_storage, :approvals_before_merge
        end
        put ':id' do
          authorize_admin_project
          attrs = map_public_to_visibility_level(declared_params(include_missing: false))
          authorize! :rename_project, user_project if attrs[:name].present?
          authorize! :change_visibility_level, user_project if attrs[:visibility_level].present?

          result = ::Projects::UpdateService.new(user_project, current_user, attrs).execute

          if result[:status] == :success
            present user_project, with: ::API::V3::Entities::Project,
                                  user_can_admin_project: can?(current_user, :admin_project, user_project)
          else
            render_validation_error!(user_project)
          end
        end

        desc 'Archive a project' do
          success ::API::V3::Entities::Project
        end
        post ':id/archive' do
          authorize!(:archive_project, user_project)

          user_project.archive!

          present user_project, with: ::API::V3::Entities::Project
        end

        desc 'Unarchive a project' do
          success ::API::V3::Entities::Project
        end
        post ':id/unarchive' do
          authorize!(:archive_project, user_project)

          user_project.unarchive!

          present user_project, with: ::API::V3::Entities::Project
        end

        desc 'Star a project' do
          success ::API::V3::Entities::Project
        end
        post ':id/star' do
          if current_user.starred?(user_project)
            not_modified!
          else
            current_user.toggle_star(user_project)
            user_project.reload

            present user_project, with: ::API::V3::Entities::Project
          end
        end

        desc 'Unstar a project' do
          success ::API::V3::Entities::Project
        end
        delete ':id/star' do
          if current_user.starred?(user_project)
            current_user.toggle_star(user_project)
            user_project.reload

            present user_project, with: ::API::V3::Entities::Project
          else
            not_modified!
          end
        end

        desc 'Remove a project'
        delete ":id" do
          authorize! :remove_project, user_project

          status(200)
          ::Projects::DestroyService.new(user_project, current_user, {}).async_execute
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
            status(200)
            user_project.forked_project_link.destroy
          else
            not_modified!
          end
        end

        desc 'Share the project with a group' do
          success ::API::Entities::ProjectGroupLink
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
            break render_api_error!("The project sharing with group is disabled", 400)
          end

          link = user_project.project_group_links.new(declared_params(include_missing: false))

          if link.save
            present link, with: ::API::Entities::ProjectGroupLink
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

          link.destroy
          no_content!
        end

        desc 'Upload a file'
        params do
          requires :file, type: File, desc: 'The file to be uploaded'
        end
        post ":id/uploads" do
          UploadService.new(user_project, params[:file]).execute
        end

        desc 'Get the users list of a project' do
          success ::API::Entities::UserBasic
        end
        params do
          optional :search, type: String, desc: 'Return list of users matching the search criteria'
          use :pagination
        end
        get ':id/users' do
          users = user_project.team.users
          users = users.search(params[:search]) if params[:search].present?

          present paginate(users), with: ::API::Entities::UserBasic
        end
      end
    end
  end
end
