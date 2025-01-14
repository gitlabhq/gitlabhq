# frozen_string_literal: true

module API
  class Groups < ::API::Base
    include PaginationParams
    include Helpers::CustomAttributes

    before do
      authenticate_non_get!
      set_current_organization
    end

    helpers Helpers::GroupsHelpers

    feature_category :groups_and_projects, ['/groups/:id/custom_attributes', '/groups/:id/custom_attributes/:key']

    helpers do
      params :statistics_params do
        optional :statistics, type: Boolean, default: false, desc: 'Include project statistics'
      end

      params :group_list_params do
        use :statistics_params
        optional :skip_groups, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'Array of group ids to exclude from list'
        optional :all_available, type: Boolean, desc: 'Show all group that you have access to'
        optional :visibility, type: String, values: Gitlab::VisibilityLevel.string_values,
          desc: 'Limit by visibility'
        optional :search, type: String, desc: 'Search for a specific group'
        optional :owned, type: Boolean, default: false, desc: 'Limit by owned by authenticated user'
        optional :order_by, type: String, values: %w[name path id similarity], default: 'name', desc: 'Order by name, path, id or similarity if searching'
        optional :sort, type: String, values: %w[asc desc], default: 'asc', desc: 'Sort by asc (ascending) or desc (descending)'
        optional :min_access_level, type: Integer, values: Gitlab::Access.all_values, desc: 'Minimum access level of authenticated user'
        optional :top_level_only, type: Boolean, desc: 'Only include top-level groups'
        use :optional_group_list_params_ee
        use :pagination
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def find_groups(params, parent_id = nil)
        find_params = params.slice(*allowable_find_params)

        find_params[:parent] = if params[:top_level_only]
                                 [nil]
                               elsif parent_id
                                 find_group!(parent_id)
                               end

        find_params[:all_available] =
          find_params.fetch(:all_available, current_user&.can_read_all_resources?)

        groups = GroupsFinder.new(current_user, find_params).execute
        groups = groups.where.not(id: params[:skip_groups]) if params[:skip_groups].present?

        order_groups(groups).with_api_scopes
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def allowable_find_params
        [:all_available,
          :custom_attributes,
          :owned, :min_access_level,
          :include_parent_descendants, :search, :visibility]
      end

      # This is a separate method so that EE can extend its behaviour, without
      # having to modify this code directly.
      #
      def create_group
        ::Groups::CreateService
          .new(current_user, translate_params_for_compatibility)
          .execute
      end

      def authorized_params?(group, params)
        return true if can?(current_user, :admin_group, group)

        can?(current_user, :admin_runner, group) &&
          params.keys == [:shared_runners_setting]
      end

      # This is a separate method so that EE can extend its behaviour, without
      # having to modify this code directly.
      #
      def update_group(group)
        safe_params = translate_params_for_compatibility
        return unauthorized! unless authorized_params?(group, safe_params)

        ::Groups::UpdateService
          .new(group, current_user, safe_params)
          .execute
      end

      def translate_params_for_compatibility
        temp_params = declared_params(include_missing: false)

        temp_params[:emails_enabled] = !temp_params.delete(:emails_disabled) if temp_params.key?(:emails_disabled)

        temp_params
      end

      def find_group_projects(params, finder_options)
        group = find_group!(params[:id])

        projects = GroupProjectsFinder.new(
          group: group,
          current_user: current_user,
          params: project_finder_params,
          options: finder_options
        ).execute

        order_by = params[:order_by]
        projects = reorder_projects_with_order_support(projects, group, order_by)

        paginate(projects)
      end

      def present_projects(params, projects)
        options = {
          with: params[:simple] ? Entities::BasicProjectDetails : Entities::Project,
          current_user: current_user
        }

        projects, options = with_custom_attributes(projects, options)

        present options[:with].prepare_relation(projects, options), options
      end

      def present_groups(params, groups, serializer: Entities::Group)
        options = {
          with: serializer,
          current_user: current_user,
          statistics: params[:statistics] && current_user&.can_read_all_resources?
        }

        groups = groups.with_statistics if options[:statistics]
        groups, options = with_custom_attributes(groups, options)

        present paginate(groups), options
      end

      def present_group_details(params, group, with_projects: true)
        options = {
          with: Entities::GroupDetail,
          with_projects: with_projects,
          current_user: current_user,
          user_can_admin_group: can?(current_user, :admin_group, group)
        }

        group, options = with_custom_attributes(group, options) if params[:with_custom_attributes]

        present group, options
      end

      def present_groups_with_pagination_strategies(params, groups)
        groups = groups.select(groups.arel_table[Arel.star])

        return present_groups(params, groups) if current_user.present?

        options = {
          with: Entities::Group,
          current_user: nil,
          statistics: false
        }

        groups, options = with_custom_attributes(groups, options)

        present paginate_with_strategies(groups), options
      end

      def delete_group(group)
        destroy_conditionally!(group) do |group|
          ::Groups::DestroyService.new(group, current_user).async_execute
        end

        accepted!
      end

      def reorder_projects_with_order_support(projects, group, order_by)
        case order_by
        when 'similarity'
          handle_similarity_order(group, projects)
        when 'star_count'
          handle_star_count_order(group, projects)
        else
          reorder_projects(projects)
        end
      end

      def order_groups(groups)
        return groups.sorted_by_similarity_and_parent_id_desc(params[:search]) if order_by_similarity?

        groups.reorder(group_without_similarity_options) # rubocop: disable CodeReuse/ActiveRecord
      end

      def group_without_similarity_options
        order_options = { params[:order_by] => params[:sort] }
        order_options['name'] = order_options.delete('similarity') if order_options.has_key?('similarity')
        order_options["id"] ||= "asc"
        order_options
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def handle_similarity_order(group, projects)
        if params[:search].present?
          projects.sorted_by_similarity_desc(params[:search])
        else
          order_options = { name: :asc }
          order_options['id'] ||= params[:sort] || 'asc'
          projects.reorder(order_options)
        end
      end

      def handle_star_count_order(group, projects)
        order_options = { star_count: params[:sort] == 'asc' ? :asc : :desc }
        order_options['id'] ||= params[:sort]
        projects.reorder(order_options)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def authorize_group_creation!
        authorize! :create_group
      end

      def check_subscription!(group)
        render_api_error!("This group can't be removed because it is linked to a subscription.", :bad_request) if group.linked_to_subscription?
      end

      # Overridden in EE
      def check_query_limit; end
    end

    resource :groups do
      include CustomAttributesEndpoints

      desc 'Get a groups list' do
        success Entities::Group
        is_array true
        tags %w[groups]
      end
      params do
        use :group_list_params
        use :with_custom_attributes
      end
      get feature_category: :groups_and_projects do
        if Feature.enabled?(:rate_limit_groups_and_projects_api, current_user)
          check_rate_limit_by_user_or_ip!(:groups_api)
        end

        groups = find_groups(declared_params(include_missing: false), params[:id])
        present_groups_with_pagination_strategies params, groups
      end

      desc 'Create a group. Available only for users who can create groups.' do
        success Entities::Group
        tags %w[groups]
      end
      params do
        requires :name, type: String, desc: 'The name of the group'
        requires :path, type: String, desc: 'The path of the group'
        optional :parent_id, type: Integer, desc: 'The parent group id for creating nested group'
        optional :organization_id, type: Integer, default: -> { Current.organization_id },
          desc: 'The organization id for the group'

        use :optional_params
      end
      post feature_category: :groups_and_projects, urgency: :low do
        organization = find_organization!(params[:organization_id]) if params[:organization_id].present?
        authorize! :create_group, organization if organization

        parent_group = find_group!(params[:parent_id], organization: organization) if params[:parent_id].present?
        if parent_group
          authorize! :create_subgroup, parent_group
        else
          authorize_group_creation!
        end

        response = create_group
        group = response[:group]
        group.preload_shared_group_links

        if response.success?
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
        tags %w[groups]
      end
      params do
        optional :name, type: String, desc: 'The name of the group'
        optional :path, type: String, desc: 'The path of the group'
        use :optional_params
        use :optional_update_params
        use :optional_update_params_ee
      end
      put ':id', feature_category: :groups_and_projects, urgency: :low do
        check_query_limit
        group = find_group!(params[:id])
        group.preload_shared_group_links

        mark_throttle! :update_namespace_name, scope: group if params.key?(:name) && params[:name].present?
        authorize_any! [:admin_group, :admin_runner], group

        group.remove_avatar! if params.key?(:avatar) && params[:avatar].nil?

        if update_group(group)
          present_group_details(params, group, with_projects: true)
        else
          render_validation_error!(group)
        end
      end

      desc 'Get a single group, with containing projects.' do
        success Entities::GroupDetail
        tags %w[groups]
      end
      params do
        use :with_custom_attributes
        optional :with_projects, type: Boolean, default: true, desc: 'Omit project details'
      end
      # TODO: Set higher urgency after resolving https://gitlab.com/gitlab-org/gitlab/-/issues/357841
      get ":id", feature_category: :groups_and_projects, urgency: :low do
        if Feature.enabled?(:rate_limit_groups_and_projects_api, current_user)
          check_rate_limit_by_user_or_ip!(:group_api)
        end

        group = find_group!(params[:id])
        group.preload_shared_group_links

        present_group_details(params, group, with_projects: params[:with_projects])
      end

      desc 'Remove a group.' do
        tags %w[groups]
      end
      delete ":id", feature_category: :groups_and_projects, urgency: :low do
        group = find_group!(params[:id])
        authorize! :remove_group, group
        check_subscription! group

        delete_group(group)
      end

      desc 'Get a list of shared groups this group was invited to' do
        success Entities::Group
        is_array true
        tags %w[groups]
      end
      params do
        optional :skip_groups, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'Array of group ids to exclude from list'
        optional :visibility, type: String, values: Gitlab::VisibilityLevel.string_values, desc: 'Limit by visibility'
        optional :search, type: String, desc: 'Search for a specific group'
        optional :min_access_level, type: Integer, values: Gitlab::Access.all_values, desc: 'Minimum access level of authenticated user'
        optional :order_by, type: String, values: %w[name path id similarity], default: 'name', desc: 'Order by name, path, id or similarity if searching'
        optional :sort, type: String, values: %w[asc desc], default: 'asc', desc: 'Sort by asc (ascending) or desc (descending)'

        use :pagination
        use :with_custom_attributes
      end
      get ":id/groups/shared", feature_category: :groups_and_projects do
        if Feature.enabled?(:rate_limit_groups_and_projects_api, current_user)
          check_rate_limit_by_user_or_ip!(:group_shared_groups_api)
        end

        group = find_group!(params[:id])
        groups = ::Namespaces::Groups::SharedGroupsFinder.new(group, current_user, declared(params)).execute
        groups = order_groups(groups).with_api_scopes
        present_groups params, groups
      end

      desc 'Get a list of invited groups in this group' do
        success Entities::Group
        is_array true
        tags %w[groups]
      end
      params do
        optional :relation, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, values: %w[direct inherited], desc: 'Include group relations'
        optional :search, type: String, desc: 'Search for a specific group'
        optional :min_access_level, type: Integer, values: Gitlab::Access.all_values, desc: 'Minimum access level of authenticated user'

        use :pagination
        use :with_custom_attributes
      end
      get ":id/invited_groups", feature_category: :groups_and_projects do
        check_rate_limit_by_user_or_ip!(:group_invited_groups_api)

        group = find_group!(params[:id])
        groups = ::Namespaces::Groups::InvitedGroupsFinder.new(group, current_user, declared_params).execute
        present_groups params, groups
      end

      desc 'Get a list of projects in this group.' do
        success Entities::Project
        is_array true
        tags %w[groups]
      end
      params do
        optional :archived, type: Boolean, desc: 'Limit by archived status'
        optional :visibility, type: String, values: Gitlab::VisibilityLevel.string_values,
          desc: 'Limit by visibility'
        optional :search, type: String, desc: 'Return list of authorized projects matching the search criteria'
        optional :order_by, type: String, values: %w[id name path created_at updated_at last_activity_at similarity star_count],
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
        optional :include_ancestor_groups, type: Boolean, default: false, desc: 'Includes projects in ancestors of this group'
        optional :min_access_level, type: Integer, values: Gitlab::Access.all_values, desc: 'Limit by minimum access level of authenticated user on projects'

        use :pagination
        use :with_custom_attributes
        use :optional_projects_params
      end
      # TODO: Set higher urgency after resolving https://gitlab.com/gitlab-org/gitlab/-/issues/211498
      get ":id/projects", feature_category: :groups_and_projects, urgency: :low do
        if Feature.enabled?(:rate_limit_groups_and_projects_api, current_user)
          check_rate_limit_by_user_or_ip!(:group_projects_api)
        end

        finder_options = {
          exclude_shared: !params[:with_shared],
          include_subgroups: params[:include_subgroups],
          include_ancestor_groups: params[:include_ancestor_groups]
        }

        projects = find_group_projects(params, finder_options)

        present_projects(params, projects)
      end

      desc 'Get a list of shared projects in this group' do
        success Entities::Project
        is_array true
        tags %w[groups]
      end
      params do
        optional :archived, type: Boolean, desc: 'Limit by archived status'
        optional :visibility, type: String, values: Gitlab::VisibilityLevel.string_values,
          desc: 'Limit by visibility'
        optional :search, type: String, desc: 'Return list of authorized projects matching the search criteria'
        optional :order_by, type: String, values: %w[id name path created_at updated_at last_activity_at star_count],
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
      get ":id/projects/shared", feature_category: :groups_and_projects do
        projects = find_group_projects(params, { only_shared: true })

        present_projects(params, projects)
      end

      desc 'Get a list of subgroups in this group.' do
        success Entities::Group
        is_array true
        tags %w[groups]
      end
      params do
        use :group_list_params
        use :with_custom_attributes
      end
      get ":id/subgroups", feature_category: :groups_and_projects, urgency: :low do
        groups = find_groups(declared_params(include_missing: false), params[:id])
        present_groups params, groups
      end

      desc 'Get a list of descendant groups of this group.' do
        success Entities::Group
        is_array true
        tags %w[groups]
      end
      params do
        use :group_list_params
        use :with_custom_attributes
      end
      get ":id/descendant_groups", feature_category: :groups_and_projects, urgency: :low do
        finder_params = declared_params(include_missing: false).merge(include_parent_descendants: true)
        groups = find_groups(finder_params, params[:id])
        present_groups params, groups
      end

      desc 'Transfer a project to the group namespace. Available only for admin.' do
        success Entities::GroupDetail
        tags %w[groups]
      end
      params do
        requires :project_id, type: String, desc: 'The ID or path of the project'
      end
      post ":id/projects/:project_id", requirements: { project_id: /.+/ }, feature_category: :groups_and_projects do
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

      desc 'Get the groups to where the current group can be transferred to' do
        success Entities::Group
        is_array true
        tags %w[groups]
      end
      params do
        optional :search, type: String, desc: 'Return list of namespaces matching the search criteria'
        use :pagination
      end
      get ':id/transfer_locations', feature_category: :groups_and_projects do
        authorize! :admin_group, user_group
        args = declared_params(include_missing: false)

        groups = ::Groups::AcceptingGroupTransfersFinder.new(current_user, user_group, args).execute
        groups = groups.with_route

        present_groups params, groups, serializer: Entities::PublicGroupDetails
      end

      desc 'Transfer a group to a new parent group or promote a subgroup to a top-level group' do
        tags %w[groups]
      end
      params do
        optional :group_id,
          type: Integer,
          desc: 'The ID of the target group to which the group needs to be transferred to.'\
                'If not provided, the source group will be promoted to a top-level group.'
      end
      post ':id/transfer', feature_category: :groups_and_projects do
        group = find_group!(params[:id])
        authorize! :admin_group, group

        new_parent_group = find_group!(params[:group_id]) if params[:group_id].present?

        service = ::Groups::TransferService.new(group, current_user)

        if service.execute(new_parent_group)
          group.preload_shared_group_links
          present group, with: Entities::GroupDetail, current_user: current_user
        else
          render_api_error!(service.error, 400)
        end
      end

      desc 'Share a group with a group' do
        success Entities::GroupDetail
        tags %w[groups]
      end
      params do
        requires :group_id, type: Integer, desc: 'The ID of the group to share'
        requires :group_access, type: Integer, values: Gitlab::Access.all_values, desc: 'The group access level'
        optional :expires_at, type: Date, desc: 'Share expiration date'
        optional :member_role_id, type: Integer, desc: 'The ID of the Member Role to be assigned to the group'
      end
      post ":id/share", feature_category: :groups_and_projects, urgency: :low do
        shared_with_group = find_group!(params[:group_id])

        group_link_create_params = {
          shared_group_access: params[:group_access],
          expires_at: params[:expires_at],
          member_role_id: params[:member_role_id]
        }

        result = ::Groups::GroupLinks::CreateService.new(user_group, shared_with_group, current_user, group_link_create_params).execute
        user_group.preload_shared_group_links

        if result[:status] == :success
          present user_group, with: Entities::GroupDetail, current_user: current_user
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end

      params do
        requires :group_id, type: Integer, desc: 'The ID of the shared group'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      delete ":id/share/:group_id", feature_category: :groups_and_projects do
        shared_group = find_group!(params[:id])

        link = shared_group.shared_with_group_links.find_by(shared_with_group_id: params[:group_id])
        not_found!('Group Link') unless link

        ::Groups::GroupLinks::DestroyService.new(shared_group, current_user).execute(link)

        no_content!
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Revoke a single token' do
        detail <<-DETAIL
Revoke a token, if it has access to the group or any of its subgroups
and projects. If the token is revoked, or was already revoked, its
details are returned in the response.

The following criteria must be met:

- The group must be a top-level group.
- You must have Owner permission in the group.
- The token type is one of:
  - Personal access token
  - Group access token
  - Project access token
  - Group deploy token
  - User feed token

This feature is gated by the :group_agnostic_token_revocation feature flag.
        DETAIL
      end
      params do
        requires :id, type: String, desc: 'The ID of a top-level group'
        requires :token, type: String, desc: 'The token to revoke'
      end
      post ":id/tokens/revoke", urgency: :low, feature_category: :groups_and_projects do
        group = find_group!(params[:id])
        not_found! unless Feature.enabled?(:group_agnostic_token_revocation, group)
        bad_request!('Must be a top-level group') if group.subgroup?
        authorize! :admin_group, group

        result = ::Groups::AgnosticTokenRevocationService.new(group, current_user, params[:token]).execute

        if result.success?
          status :ok
          present result.payload[:revocable], with: "API::Entities::#{result.payload[:api_entity]}".constantize
        else
          # No matter the error, we always return a 422.
          # This prevents disclosing cases like: token is invalid,
          # or token is valid but in a different group.
          unprocessable_entity!
        end
      end
    end
  end
end

API::Groups.prepend_mod_with('API::Groups')
