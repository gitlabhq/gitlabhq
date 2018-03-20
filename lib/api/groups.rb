module API
  class Groups < Grape::API
    include PaginationParams
    include Helpers::CustomAttributes

    before { authenticate_non_get! }

    helpers do
      params :optional_params_ce do
        optional :description, type: String, desc: 'The description of the group'
        optional :visibility, type: String,
                              values: Gitlab::VisibilityLevel.string_values,
                              default: Gitlab::VisibilityLevel.string_level(
                                Gitlab::CurrentSettings.current_application_settings.default_group_visibility),
                              desc: 'The visibility of the group'
        optional :lfs_enabled, type: Boolean, desc: 'Enable/disable LFS for the projects in this group'
        optional :request_access_enabled, type: Boolean, desc: 'Allow users to request member access'
        optional :share_with_group_lock, type: Boolean, desc: 'Prevent sharing a project with another group within this group'
      end

      params :optional_params do
        use :optional_params_ce
      end

      params :statistics_params do
        optional :statistics, type: Boolean, default: false, desc: 'Include project statistics'
      end

      params :group_list_params do
        use :statistics_params
        optional :skip_groups, type: Array[Integer], desc: 'Array of group ids to exclude from list'
        optional :all_available, type: Boolean, desc: 'Show all group that you have access to'
        optional :search, type: String, desc: 'Search for a specific group'
        optional :owned, type: Boolean, default: false, desc: 'Limit by owned by authenticated user'
        optional :order_by, type: String, values: %w[name path], default: 'name', desc: 'Order by name or path'
        optional :sort, type: String, values: %w[asc desc], default: 'asc', desc: 'Sort by asc (ascending) or desc (descending)'
        use :pagination
      end

      def find_groups(params)
        find_params = {
          all_available: params[:all_available],
          custom_attributes: params[:custom_attributes],
          owned: params[:owned]
        }
        find_params[:parent] = find_group!(params[:id]) if params[:id]

        groups = GroupsFinder.new(current_user, find_params).execute
        groups = groups.search(params[:search]) if params[:search].present?
        groups = groups.where.not(id: params[:skip_groups]) if params[:skip_groups].present?
        groups = groups.reorder(params[:order_by] => params[:sort])

        groups
      end

      def find_group_projects(params)
        group = find_group!(params[:id])
        projects = GroupProjectsFinder.new(group: group, current_user: current_user, params: project_finder_params).execute
        projects = reorder_projects(projects)
        paginate(projects)
      end

      def present_groups(params, groups)
        options = {
          with: Entities::Group,
          current_user: current_user,
          statistics: params[:statistics] && current_user.admin?
        }

        groups = groups.with_statistics if options[:statistics]
        groups, options = with_custom_attributes(groups, options)

        present paginate(groups), options
      end
    end

    resource :groups do
      include CustomAttributesEndpoints

      desc 'Get a groups list' do
        success Entities::Group
      end
      params do
        use :group_list_params
        use :with_custom_attributes
      end
      get do
        groups = find_groups(params)
        present_groups params, groups
      end

      desc 'Create a group. Available only for users who can create groups.' do
        success Entities::Group
      end
      params do
        requires :name, type: String, desc: 'The name of the group'
        requires :path, type: String, desc: 'The path of the group'

        if ::Group.supports_nested_groups?
          optional :parent_id, type: Integer, desc: 'The parent group id for creating nested group'
        end

        use :optional_params
      end
      post do
        parent_group = find_group!(params[:parent_id]) if params[:parent_id].present?
        if parent_group
          authorize! :create_subgroup, parent_group
        else
          authorize! :create_group
        end
        
        opts = declared_params(include_missing: false)
        opts[:visibility_level] = Gitlab::VisibilityLevel.level_value opts[:visibility]

        group = ::Groups::CreateService.new(current_user, opts).execute

        if group.persisted?
          present group, with: Entities::GroupDetail, current_user: current_user
        else
          render_api_error!("Failed to save group #{group.errors.messages}", 400)
        end
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      desc 'Update a group. Available only for users who can administrate groups.' do
        success Entities::Group
      end
      params do
        optional :name, type: String, desc: 'The name of the group'
        optional :path, type: String, desc: 'The path of the group'
        use :optional_params
      end
      put ':id' do
        group = find_group!(params[:id])
        authorize! :admin_group, group
        
        opts = declared_params(include_missing: false)
        opts[:visibility_level] = Gitlab::VisibilityLevel.level_value opts[:visibility]

        if ::Groups::UpdateService.new(group, current_user, opts).execute
          present group, with: Entities::GroupDetail, current_user: current_user
        else
          render_validation_error!(group)
        end
      end

      desc 'Get a single group, with containing projects.' do
        success Entities::GroupDetail
      end
      params do
        use :with_custom_attributes
      end
      get ":id" do
        group = find_group!(params[:id])

        options = {
          with: Entities::GroupDetail,
          current_user: current_user
        }

        group, options = with_custom_attributes(group, options)

        present group, options
      end

      desc 'Remove a group.'
      delete ":id" do
        group = find_group!(params[:id])
        authorize! :admin_group, group

        destroy_conditionally!(group) do |group|
          ::Groups::DestroyService.new(group, current_user).execute
        end
      end

      desc 'Get a list of projects in this group.' do
        success Entities::Project
      end
      params do
        optional :archived, type: Boolean, default: false, desc: 'Limit by archived status'
        optional :visibility, type: String, values: Gitlab::VisibilityLevel.string_values,
                              desc: 'Limit by visibility'
        optional :search, type: String, desc: 'Return list of authorized projects matching the search criteria'
        optional :order_by, type: String, values: %w[id name path created_at updated_at last_activity_at],
                            default: 'created_at', desc: 'Return projects ordered by field'
        optional :sort, type: String, values: %w[asc desc], default: 'desc',
                        desc: 'Return projects sorted in ascending and descending order'
        optional :simple, type: Boolean, default: false,
                          desc: 'Return only the ID, URL, name, and path of each project'
        optional :owned, type: Boolean, default: false, desc: 'Limit by owned by authenticated user'
        optional :starred, type: Boolean, default: false, desc: 'Limit by starred status'

        use :pagination
        use :with_custom_attributes
      end
      get ":id/projects" do
        projects = find_group_projects(params)

        options = {
          with: params[:simple] ? Entities::BasicProjectDetails : Entities::Project,
          current_user: current_user
        }

        projects, options = with_custom_attributes(projects, options)

        present options[:with].prepare_relation(projects), options
      end

      desc 'Get a list of subgroups in this group.' do
        success Entities::Group
      end
      params do
        use :group_list_params
        use :with_custom_attributes
      end
      get ":id/subgroups" do
        groups = find_groups(params)
        present_groups params, groups
      end

      desc 'Transfer a project to the group namespace. Available only for admin.' do
        success Entities::GroupDetail
      end
      params do
        requires :project_id, type: String, desc: 'The ID or path of the project'
      end
      post ":id/projects/:project_id", requirements: { project_id: /.+/ } do
        authenticated_as_admin!
        group = find_group!(params[:id])
        project = find_project!(params[:project_id])
        result = ::Projects::TransferService.new(project, current_user).execute(group)

        if result
          present group, with: Entities::GroupDetail, current_user: current_user
        else
          render_api_error!("Failed to transfer project #{project.errors.messages}", 400)
        end
      end
    end
  end
end
