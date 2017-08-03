module API
  class Groups < Grape::API
    include PaginationParams

    before { authenticate! }

    helpers do
      params :optional_params_ce do
        optional :description, type: String, desc: 'The description of the group'
        optional :visibility, type: String, values: Gitlab::VisibilityLevel.string_values, desc: 'The visibility of the group'
        optional :lfs_enabled, type: Boolean, desc: 'Enable/disable LFS for the projects in this group'
        optional :request_access_enabled, type: Boolean, desc: 'Allow users to request member access'
        optional :share_with_group_lock, type: Boolean, desc: 'Prevent sharing a project with another group within this group'
      end

      params :optional_params_ee do
        optional :membership_lock, type: Boolean, desc: 'Prevent adding new members to project membership within this group'
        optional :ldap_cn, type: String, desc: 'LDAP Common Name'
        optional :ldap_access, type: Integer, desc: 'A valid access level'
        optional :shared_runners_minutes_limit, type: Integer, desc: '(admin-only) Pipeline minutes quota for this group'
        all_or_none_of :ldap_cn, :ldap_access
      end

      params :optional_params do
        use :optional_params_ce
        use :optional_params_ee
      end

      params :statistics_params do
        optional :statistics, type: Boolean, default: false, desc: 'Include project statistics'
      end

      def present_groups(groups, options = {})
        options = options.reverse_merge(
          with: Entities::Group,
          current_user: current_user
        )

        groups = groups.with_statistics if options[:statistics]
        present paginate(groups), options
      end
    end

    resource :groups do
      desc 'Get a groups list' do
        success Entities::Group
      end
      params do
        use :statistics_params
        optional :skip_groups, type: Array[Integer], desc: 'Array of group ids to exclude from list'
        optional :all_available, type: Boolean, desc: 'Show all group that you have access to'
        optional :search, type: String, desc: 'Search for a specific group'
        optional :owned, type: Boolean, default: false, desc: 'Limit by owned by authenticated user'
        optional :order_by, type: String, values: %w[name path], default: 'name', desc: 'Order by name or path'
        optional :sort, type: String, values: %w[asc desc], default: 'asc', desc: 'Sort by asc (ascending) or desc (descending)'
        use :pagination
      end
      get do
        groups = if params[:owned]
                   current_user.owned_groups
                 elsif current_user.admin
                   Group.all
                 elsif params[:all_available]
                   GroupsFinder.new(current_user).execute
                 else
                   current_user.groups
                 end

        groups = groups.search(params[:search]) if params[:search].present?
        groups = groups.where.not(id: params[:skip_groups]) if params[:skip_groups].present?
        groups = groups.reorder(params[:order_by] => params[:sort])

        present_groups groups, statistics: params[:statistics] && current_user.admin?
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
        authorize! :create_group

        ldap_link_attrs = {
          cn: params.delete(:ldap_cn),
          group_access: params.delete(:ldap_access)
        }

        # EE
        authenticated_as_admin! if params[:shared_runners_minutes_limit]

        group = ::Groups::CreateService.new(current_user, declared_params(include_missing: false)).execute

        if group.persisted?
          # NOTE: add backwards compatibility for single ldap link
          if ldap_link_attrs[:cn].present?
            group.ldap_group_links.create(
              cn: ldap_link_attrs[:cn],
              group_access: ldap_link_attrs[:group_access]
            )
          end

          present group, with: Entities::GroupDetail, current_user: current_user
        else
          render_api_error!("Failed to save group #{group.errors.messages}", 400)
        end
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups, requirements: { id: %r{[^/]+} } do
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

        # EE
        if params[:shared_runners_minutes_limit].present? &&
            group.shared_runners_minutes_limit.to_i !=
                params[:shared_runners_minutes_limit].to_i
          authenticated_as_admin!
        end

        if ::Groups::UpdateService.new(group, current_user, declared_params(include_missing: false)).execute
          present group, with: Entities::GroupDetail, current_user: current_user
        else
          render_validation_error!(group)
        end
      end

      desc 'Get a single group, with containing projects.' do
        success Entities::GroupDetail
      end
      get ":id" do
        group = find_group!(params[:id])
        present group, with: Entities::GroupDetail, current_user: current_user
      end

      desc 'Remove a group.'
      delete ":id" do
        group = find_group!(params[:id])
        authorize! :admin_group, group

        status 204
        ::Groups::DestroyService.new(group, current_user).execute
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
      end
      get ":id/projects" do
        group = find_group!(params[:id])
        projects = GroupProjectsFinder.new(group: group, current_user: current_user, params: project_finder_params).execute
        projects = reorder_projects(projects)
        entity = params[:simple] ? Entities::BasicProjectDetails : Entities::Project
        present paginate(projects), with: entity, current_user: current_user
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
