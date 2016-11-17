module API
  class Groups < Grape::API
    before { authenticate! }

    helpers do
      params :optional_params do
        optional :description, type: String, desc: 'The description of the group'
        optional :visibility_level, type: Integer, desc: 'The visibility level of the group'
        optional :lfs_enabled, type: Boolean, desc: 'Enable/disable LFS for the projects in this group'
        optional :request_access_enabled, type: Boolean, desc: 'Allow users to request member access'
        optional :membership_lock, type: Boolean, desc: 'Prevent adding new members to project membership within this group'
        optional :share_with_group_lock, type: Boolean, desc: 'Prevent sharing a project with another group within this group'
      end

      params :optional_params_ee do
        optional :ldap_cn, type: String, desc: 'LDAP Common Name'
        optional :ldap_access, type: Integer, desc: 'A valid access level'
        all_or_none_of :ldap_cn, :ldap_access
      end
    end

    resource :groups do
      desc 'Get a groups list' do
        success Entities::Group
      end
      params do
        optional :skip_groups, type: Array[Integer], desc: 'Array of group ids to exclude from list'
        optional :all_available, type: Boolean, desc: 'Show all group that you have access to'
        optional :search, type: String, desc: 'Search for a specific group'
      end
      get do
        groups = if current_user.admin
                   Group.all
                 elsif params[:all_available]
                   GroupsFinder.new.execute(current_user)
                 else
                   current_user.groups
                 end

        groups = groups.search(params[:search]) if params[:search].present?
        groups = groups.where.not(id: params[:skip_groups]) if params[:skip_groups].present?
        present paginate(groups), with: Entities::Group
      end

      desc 'Get list of owned groups for authenticated user' do
        success Entities::Group
      end
      get '/owned' do
        groups = current_user.owned_groups
        present paginate(groups), with: Entities::Group, user: current_user
      end

      desc 'Create a group. Available only for users who can create groups.' do
        success Entities::Group
      end
      params do
        requires :name, type: String, desc: 'The name of the group'
        requires :path, type: String, desc: 'The path of the group'
        use :optional_params
        use :optional_params_ee
      end
      post do
        authorize! :create_group

        ldap_link_attrs = {
          cn: params.delete(:ldap_cn),
          group_access: params.delete(:ldap_access)
        }

        group = ::Groups::CreateService.new(current_user, declared_params(include_missing: false)).execute

        if group.persisted?
          # NOTE: add backwards compatibility for single ldap link
          if ldap_link_attrs[:cn].present?
            group.ldap_group_links.create(
              cn: ldap_link_attrs[:cn],
              group_access: ldap_link_attrs[:group_access]
            )
          end

          present group, with: Entities::Group
        else
          render_api_error!("Failed to save group #{group.errors.messages}", 400)
        end
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups do
      desc 'Update a group. Available only for users who can administrate groups.' do
        success Entities::Group
      end
      params do
        optional :name, type: String, desc: 'The name of the group'
        optional :path, type: String, desc: 'The path of the group'
        use :optional_params
        at_least_one_of :name, :path, :description, :visibility_level,
                        :lfs_enabled, :request_access_enabled
      end
      put ':id' do
        group = find_group(params[:id])
        authorize! :admin_group, group

        if ::Groups::UpdateService.new(group, current_user, declared_params(include_missing: false)).execute
          present group, with: Entities::GroupDetail
        else
          render_validation_error!(group)
        end
      end

      desc 'Get a single group, with containing projects.' do
        success Entities::GroupDetail
      end
      get ":id" do
        group = find_group(params[:id])
        present group, with: Entities::GroupDetail
      end

      desc 'Remove a group.'
      delete ":id" do
        group = find_group(params[:id])
        authorize! :admin_group, group
        DestroyGroupService.new(group, current_user).execute
      end

      desc 'Get a list of projects in this group.' do
        success Entities::Project
      end
      get ":id/projects" do
        group = find_group(params[:id])
        projects = GroupProjectsFinder.new(group).execute(current_user)
        projects = paginate projects
        present projects, with: Entities::Project, user: current_user
      end

      desc 'Transfer a project to the group namespace. Available only for admin.' do
        success Entities::GroupDetail
      end
      params do
        requires :project_id, type: String, desc: 'The ID of the project'
      end
      post ":id/projects/:project_id" do
        authenticated_as_admin!
        group = Group.find_by(id: params[:id])
        project = Project.find(params[:project_id])
        result = ::Projects::TransferService.new(project, current_user).execute(group)

        if result
          present group, with: Entities::GroupDetail
        else
          render_api_error!("Failed to transfer project #{project.errors.messages}", 400)
        end
      end
    end
  end
end
