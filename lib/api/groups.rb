# frozen_string_literal: true

module API
  class Groups < ::API::Base
    include PaginationParams
    include Helpers::CustomAttributes

    before { authenticate_non_get! }

    feature_category :subgroups

    helpers Helpers::GroupsHelpers

    helpers do
      params :statistics_params do
        optional :statistics, type: Boolean, default: false, desc: 'Include project statistics'
      end

      params :group_list_params do
        use :statistics_params
        optional :skip_groups, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'Array of group ids to exclude from list'
        optional :all_available, type: Boolean, desc: 'Show all group that you have access to'
        optional :search, type: String, desc: 'Search for a specific group'
        optional :owned, type: Boolean, default: false, desc: 'Limit by owned by authenticated user'
        optional :order_by, type: String, values: %w[name path id similarity], default: 'name', desc: 'Order by name, path, id or similarity if searching'
        optional :sort, type: String, values: %w[asc desc], default: 'asc', desc: 'Sort by asc (ascending) or desc (descending)'
        optional :min_access_level, type: Integer, values: Gitlab::Access.all_values, desc: 'Minimum access level of authenticated user'
        optional :top_level_only, type: Boolean, desc: 'Only include top level groups'
        use :pagination
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def find_groups(params, parent_id = nil)
        find_params = params.slice(
          :all_available,
          :custom_attributes,
          :owned, :min_access_level,
          :include_parent_descendants
        )

        find_params[:parent] = if params[:top_level_only]
                                 [nil]
                               elsif parent_id
                                 find_group!(parent_id)
                               end

        find_params[:all_available] =
          find_params.fetch(:all_available, current_user&.can_read_all_resources?)

        groups = GroupsFinder.new(current_user, find_params).execute
        groups = groups.search(params[:search], include_parents: true) if params[:search].present?
        groups = groups.where.not(id: params[:skip_groups]) if params[:skip_groups].present?

        order_groups(groups)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def create_group
        # This is a separate method so that EE can extend its behaviour, without
        # having to modify this code directly.
        ::Groups::CreateService
          .new(current_user, declared_params(include_missing: false))
          .execute
      end

      def update_group(group)
        # This is a separate method so that EE can extend its behaviour, without
        # having to modify this code directly.
        ::Groups::UpdateService
          .new(group, current_user, declared_params(include_missing: false))
          .execute
      end

      def find_group_projects(params, finder_options)
        group = find_group!(params[:id])

        projects = GroupProjectsFinder.new(
          group: group,
          current_user: current_user,
          params: project_finder_params,
          options: finder_options
        ).execute
        projects = reorder_projects_with_similarity_order_support(group, projects)
        paginate(projects)
      end

      def present_projects(params, projects)
        options = {
          with: params[:simple] ? Entities::BasicProjectDetails : Entities::Project,
          current_user: current_user
        }

        projects, options = with_custom_attributes(projects, options)

        present options[:with].prepare_relation(projects), options
      end

      def present_groups(params, groups)
        options = {
          with: Entities::Group,
          current_user: current_user,
          statistics: params[:statistics] && current_user&.admin?
        }

        groups = groups.with_statistics if options[:statistics]
        groups, options = with_custom_attributes(groups, options)

        present paginate(groups), options
      end

      def delete_group(group)
        destroy_conditionally!(group) do |group|
          ::Groups::DestroyService.new(group, current_user).async_execute
        end

        accepted!
      end

      def reorder_projects_with_similarity_order_support(group, projects)
        return handle_similarity_order(group, projects) if params[:order_by] == 'similarity'

        reorder_projects(projects)
      end

      def order_groups(groups)
        return groups.sorted_by_similarity_and_parent_id_desc(params[:search]) if order_by_similarity?

        groups.reorder(group_without_similarity_options) # rubocop: disable CodeReuse/ActiveRecord
      end

      def order_by_similarity?
        params[:order_by] == 'similarity' && params[:search].present?
      end

      def group_without_similarity_options
        order_options = { params[:order_by] => params[:sort] }
        order_options['name'] = order_options.delete('similarity') if order_options.has_key?('similarity')
        order_options["id"] ||= "asc"
        order_options
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def handle_similarity_order(group, projects)
        if params[:search].present? && Feature.enabled?(:similarity_search, group, default_enabled: true)
          projects.sorted_by_similarity_desc(params[:search])
        else
          order_options = { name: :asc }
          order_options['id'] ||= params[:sort] || 'asc'
          projects.reorder(order_options)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def authorize_group_creation!
        authorize! :create_group
      end

      def check_subscription!(group)
        render_api_error!("This group can't be removed because it is linked to a subscription.", :bad_request) if group.paid?
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
        groups = find_groups(declared_params(include_missing: false), params[:id])
        present_groups params, groups
      end

      desc 'Create a group. Available only for users who can create groups.' do
        success Entities::Group
      end
      params do
        requires :name, type: String, desc: 'The name of the group'
        requires :path, type: String, desc: 'The path of the group'
        optional :parent_id, type: Integer, desc: 'The parent group id for creating nested group'

        use :optional_params
      end
      post do
        parent_group = find_group!(params[:parent_id]) if params[:parent_id].present?
        if parent_group
          authorize! :create_subgroup, parent_group
        else
          authorize_group_creation!
        end

        group = create_group
        group.preload_shared_group_links

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
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Update a group. Available only for users who can administrate groups.' do
        success Entities::Group
      end
      params do
        optional :name, type: String, desc: 'The name of the group'
        optional :path, type: String, desc: 'The path of the group'
        use :optional_params
        use :optional_update_params
        use :optional_update_params_ee
      end
      put ':id' do
        group = find_group!(params[:id])
        group.preload_shared_group_links

        authorize! :admin_group, group

        if update_group(group)
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
        optional :with_projects, type: Boolean, default: true, desc: 'Omit project details'
      end
      get ":id" do
        group = find_group!(params[:id])
        group.preload_shared_group_links

        options = {
          with: params[:with_projects] ? Entities::GroupDetail : Entities::Group,
          current_user: current_user,
          user_can_admin_group: can?(current_user, :admin_group, group)
        }

        group, options = with_custom_attributes(group, options)

        present group, options
      end

      desc 'Remove a group.'
      delete ":id" do
        group = find_group!(params[:id])
        authorize! :admin_group, group
        check_subscription! group

        delete_group(group)
      end

      desc 'Get a list of projects in this group.' do
        success Entities::Project
      end
      params do
        optional :archived, type: Boolean, desc: 'Limit by archived status'
        optional :visibility, type: String, values: Gitlab::VisibilityLevel.string_values,
                              desc: 'Limit by visibility'
        optional :search, type: String, desc: 'Return list of authorized projects matching the search criteria'
        optional :order_by, type: String, values: %w[id name path created_at updated_at last_activity_at similarity],
                            default: 'created_at', desc: 'Return projects ordered by field'
        optional :sort, type: String, values: %w[asc desc], default: 'desc',
                        desc: 'Return projects sorted in ascending and descending order'
        optional :simple, type: Boolean, default: false,
                          desc: 'Return only the ID, URL, name, and path of each project'
        optional :owned, type: Boolean, default: false, desc: 'Limit by owned by authenticated user'
        optional :starred, type: Boolean, default: false, desc: 'Limit by starred status'
        optional :with_issues_enabled, type: Boolean, default: false, desc: 'Limit by enabled issues feature'
        optional :with_merge_requests_enabled, type: Boolean, default: false, desc: 'Limit by enabled merge requests feature'
        optional :with_shared, type: Boolean, default: true, desc: 'Include projects shared to this group'
        optional :include_subgroups, type: Boolean, default: false, desc: 'Includes projects in subgroups of this group'
        optional :min_access_level, type: Integer, values: Gitlab::Access.all_values, desc: 'Limit by minimum access level of authenticated user on projects'

        use :pagination
        use :with_custom_attributes
        use :optional_projects_params
      end
      get ":id/projects" do
        finder_options = {
          only_owned: !params[:with_shared],
          include_subgroups: params[:include_subgroups]
        }

        projects = find_group_projects(params, finder_options)

        present_projects(params, projects)
      end

      desc 'Get a list of shared projects in this group' do
        success Entities::Project
      end
      params do
        optional :archived, type: Boolean, desc: 'Limit by archived status'
        optional :visibility, type: String, values: Gitlab::VisibilityLevel.string_values,
                              desc: 'Limit by visibility'
        optional :search, type: String, desc: 'Return list of authorized projects matching the search criteria'
        optional :order_by, type: String, values: %w[id name path created_at updated_at last_activity_at],
                            default: 'created_at', desc: 'Return projects ordered by field'
        optional :sort, type: String, values: %w[asc desc], default: 'desc',
                        desc: 'Return projects sorted in ascending and descending order'
        optional :simple, type: Boolean, default: false,
                          desc: 'Return only the ID, URL, name, and path of each project'
        optional :starred, type: Boolean, default: false, desc: 'Limit by starred status'
        optional :with_issues_enabled, type: Boolean, default: false, desc: 'Limit by enabled issues feature'
        optional :with_merge_requests_enabled, type: Boolean, default: false, desc: 'Limit by enabled merge requests feature'
        optional :min_access_level, type: Integer, values: Gitlab::Access.all_values, desc: 'Limit by minimum access level of authenticated user on projects'

        use :pagination
        use :with_custom_attributes
      end
      get ":id/projects/shared" do
        projects = find_group_projects(params, { only_shared: true })

        present_projects(params, projects)
      end

      desc 'Get a list of subgroups in this group.' do
        success Entities::Group
      end
      params do
        use :group_list_params
        use :with_custom_attributes
      end
      get ":id/subgroups" do
        groups = find_groups(declared_params(include_missing: false), params[:id])
        present_groups params, groups
      end

      desc 'Get a list of descendant groups of this group.' do
        success Entities::Group
      end
      params do
        use :group_list_params
        use :with_custom_attributes
      end
      get ":id/descendant_groups" do
        finder_params = declared_params(include_missing: false).merge(include_parent_descendants: true)
        groups = find_groups(finder_params, params[:id])
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
        group.preload_shared_group_links
        project = find_project!(params[:project_id])
        result = ::Projects::TransferService.new(project, current_user).execute(group)

        if result
          present group, with: Entities::GroupDetail, current_user: current_user
        else
          render_api_error!("Failed to transfer project #{project.errors.messages}", 400)
        end
      end

      desc 'Share a group with a group' do
        success Entities::GroupDetail
      end
      params do
        requires :group_id, type: Integer, desc: 'The ID of the group to share'
        requires :group_access, type: Integer, values: Gitlab::Access.all_values, desc: 'The group access level'
        optional :expires_at, type: Date, desc: 'Share expiration date'
      end
      post ":id/share" do
        shared_group = find_group!(params[:id])
        shared_with_group = find_group!(params[:group_id])

        group_link_create_params = {
          shared_group_access: params[:group_access],
          expires_at: params[:expires_at]
        }

        result = ::Groups::GroupLinks::CreateService.new(shared_group, shared_with_group, current_user, group_link_create_params).execute
        shared_group.preload_shared_group_links

        if result[:status] == :success
          present shared_group, with: Entities::GroupDetail, current_user: current_user
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end

      params do
        requires :group_id, type: Integer, desc: 'The ID of the shared group'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      delete ":id/share/:group_id" do
        shared_group = find_group!(params[:id])

        link = shared_group.shared_with_group_links.find_by(shared_with_group_id: params[:group_id])
        not_found!('Group Link') unless link

        ::Groups::GroupLinks::DestroyService.new(shared_group, current_user).execute(link)

        no_content!
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end

API::Groups.prepend_mod_with('API::Groups')
