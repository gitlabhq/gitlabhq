module API
  # groups API
  class Groups < Grape::API
    before { authenticate! }

    resource :groups do
      # Get a groups list
      #
      # Example Request:
      #  GET /groups
      get do
        @groups = if current_user.admin
                    Group.all
                  else
                    current_user.groups
                  end

        @groups = @groups.search(params[:search]) if params[:search].present?
        @groups = paginate @groups
        present @groups, with: Entities::Group
      end

      # Create group. Available only for users who can create groups.
      #
      # Parameters:
      #   name (required)                           - The name of the group
      #   path (required)                           - The path of the group
      #   description (optional)                    - The description of the group
      #   visibility_level (optional)               - The visibility level of the group
      #   membership_lock       (optional, boolean) - Prevent adding new members to project membership within this group
      #   share_with_group_lock (optional, boolean) - Prevent sharing a project with another group within this group
      # Example Request:
      #   POST /groups
      post do
        authorize! :create_group
        required_attributes! [:name, :path]

        attrs = attributes_for_keys [:name, :path, :description, :visibility_level, :membership_lock, :share_with_group_lock]
        @group = Group.new(attrs)

        if @group.save
          # NOTE: add backwards compatibility for single ldap link
          ldap_attrs = attributes_for_keys [:ldap_cn, :ldap_access]
          if ldap_attrs.present?
            @group.ldap_group_links.create({
              cn: ldap_attrs[:ldap_cn],
              group_access: ldap_attrs[:ldap_access]
            })
          end

          @group.add_owner(current_user)
          present @group, with: Entities::Group
        else
          render_api_error!("Failed to save group #{@group.errors.messages}", 400)
        end
      end

      # Update group. Available only for users who can manage this group.
      #
      # Parameters:
      #   id (required)                             - The ID of a group
      #   name (required)                           - The name of the group
      #   path (required)                           - The path of the group
      #   description (optional)                    - The details of the group
      #   visibility_level (optional)               - The visibility level of the group
      #   membership_lock (optional, boolean)       - Prevent adding new members to project membership within this group
      #   share_with_group_lock (optional, boolean) - Prevent sharing a project with another group within this group
      # Example Request:
      #   PUT /groups/:id
      put ':id' do
        group = find_group(params[:id])
        authorize! :admin_group, group

        attrs = attributes_for_keys [:name, :path, :description, :visibility_level, :membership_lock, :share_with_group_lock]

        if ::Groups::UpdateService.new(group, current_user, attrs).execute
          present group, with: Entities::GroupDetail
        else
          render_validation_error!(group)
        end
      end

      # Get a single group, with containing projects
      #
      # Parameters:
      #   id (required) - The ID of a group
      # Example Request:
      #   GET /groups/:id
      get ":id" do
        group = find_group(params[:id])
        present group, with: Entities::GroupDetail
      end

      # Remove group
      #
      # Parameters:
      #   id (required) - The ID of a group
      # Example Request:
      #   DELETE /groups/:id
      delete ":id" do
        group = find_group(params[:id])
        authorize! :admin_group, group
        DestroyGroupService.new(group, current_user).execute
      end

      # Get a list of projects in this group
      #
      # Example Request:
      #   GET /groups/:id/projects
      get ":id/projects" do
        group = find_group(params[:id])
        projects = GroupProjectsFinder.new(group).execute(current_user)
        projects = paginate projects
        present projects, with: Entities::Project, user: current_user
      end

      # Transfer a project to the Group namespace
      #
      # Parameters:
      #   id - group id
      #   project_id  - project id
      # Example Request:
      #   POST /groups/:id/projects/:project_id
      post ":id/projects/:project_id" do
        authenticated_as_admin!
        group = Group.find_by(id: params[:id])
        project = Project.find(params[:project_id])
        result = ::Projects::TransferService.new(project, current_user).execute(group)

        if result
          present group
        else
          render_api_error!("Failed to transfer project #{project.errors.messages}", 400)
        end
      end
    end
  end
end
