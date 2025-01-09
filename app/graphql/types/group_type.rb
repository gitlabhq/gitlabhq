# frozen_string_literal: true

module Types
  class GroupType < NamespaceType
    graphql_name 'Group'

    authorize :read_group

    expose_permissions Types::PermissionTypes::Group

    field :web_url,
      type: GraphQL::Types::String,
      null: false,
      description: 'Web URL of the group.'

    field :organization_edit_path, GraphQL::Types::String,
      null: true,
      description: 'Path for editing group at the organization level.',
      experiment: { milestone: '17.1' }

    field :avatar_url,
      type: GraphQL::Types::String,
      null: true,
      description: 'Avatar URL of the group.'

    field :created_at, Types::TimeType,
      null: true,
      description: 'Timestamp of the group creation.'

    field :updated_at, Types::TimeType,
      null: true,
      description: 'Timestamp of when the group was last updated.'

    field :custom_emoji,
      type: Types::CustomEmojiType.connection_type,
      null: true,
      resolver: Resolvers::CustomEmojiResolver,
      description: 'Custom emoji in this namespace.'

    field :share_with_group_lock,
      type: GraphQL::Types::Boolean,
      null: true,
      description: 'Indicates if sharing a project with another group within this group is prevented.'

    field :project_creation_level,
      type: GraphQL::Types::String,
      null: true,
      method: :project_creation_level_str,
      description: 'Permission level required to create projects in the group.'

    field :subgroup_creation_level,
      type: GraphQL::Types::String,
      null: true,
      method: :subgroup_creation_level_str,
      description: 'Permission level required to create subgroups within the group.'

    field :require_two_factor_authentication,
      type: GraphQL::Types::Boolean,
      null: true,
      description: 'Indicates if all users in this group are required to set up two-factor authentication.'

    field :two_factor_grace_period,
      type: GraphQL::Types::Int,
      null: true,
      description: 'Time before two-factor authentication is enforced.'

    field :auto_devops_enabled,
      type: GraphQL::Types::Boolean,
      null: true,
      description: 'Indicates whether Auto DevOps is enabled for all projects within this group.'

    field :emails_disabled,
      type: GraphQL::Types::Boolean,
      null: true,
      description: 'Indicates if a group has email notifications disabled.'

    field :emails_enabled,
      type: GraphQL::Types::Boolean,
      null: true,
      description: 'Indicates if a group has email notifications enabled.'

    field :max_access_level, Types::AccessLevelType,
      null: false,
      description: 'The maximum access level of the current user in the group.'

    field :mentions_disabled,
      type: GraphQL::Types::Boolean,
      null: true,
      description: 'Indicates if a group is disabled from getting mentioned.'

    field :parent,
      type: GroupType,
      null: true,
      description: 'Parent group.'

    field :issues,
      Types::IssueType.connection_type,
      null: true,
      description: 'Issues for projects in this group.',
      resolver: Resolvers::GroupIssuesResolver

    field :merge_requests,
      Types::MergeRequestType.connection_type,
      null: true,
      description: 'Merge requests for projects in this group.',
      resolver: Resolvers::GroupMergeRequestsResolver

    field :environment_scopes,
      Types::Ci::GroupEnvironmentScopeType.connection_type,
      description: 'Environment scopes of the group.',
      null: true,
      authorize: :admin_cicd_variables,
      resolver: Resolvers::GroupEnvironmentScopesResolver

    field :milestones,
      description: 'Milestones of the group.',
      extras: [:lookahead],
      resolver: Resolvers::GroupMilestonesResolver

    field :boards,
      Types::BoardType.connection_type,
      null: true,
      description: 'Boards of the group.',
      max_page_size: 2000,
      resolver: Resolvers::BoardsResolver

    field :recent_issue_boards,
      Types::BoardType.connection_type,
      null: true,
      description: 'List of recently visited boards of the group. Maximum size is 4.',
      resolver: Resolvers::RecentBoardsResolver

    field :board,
      Types::BoardType,
      null: true,
      description: 'A single board of the group.',
      resolver: Resolvers::BoardResolver

    field :label,
      Types::LabelType,
      null: true,
      description: 'Label available on this group.' do
      argument :title,
        type: GraphQL::Types::String,
        required: true,
        description: 'Title of the label.'
    end

    field :group_members,
      description: 'A membership of a user within this group.',
      resolver: Resolvers::GroupMembersResolver

    field :container_repositories,
      Types::ContainerRegistry::ContainerRepositoryType.connection_type,
      null: true,
      description: 'Container repositories of the group.',
      resolver: Resolvers::ContainerRepositoriesResolver,
      authorize: :read_container_image

    field :container_repositories_count,
      type: GraphQL::Types::Int,
      null: false,
      description: 'Number of container repositories in the group.'

    field :packages,
      description: 'Packages of the group. This field can only be resolved for one group in any single request.',
      resolver: Resolvers::GroupPackagesResolver

    field :dependency_proxy_setting,
      Types::DependencyProxy::GroupSettingType,
      null: true,
      description: 'Dependency Proxy settings for the group.'

    field :dependency_proxy_manifests,
      Types::DependencyProxy::ManifestType.connection_type,
      null: true,
      description: 'Dependency Proxy manifests.'

    field :dependency_proxy_blobs,
      Types::DependencyProxy::BlobType.connection_type,
      null: true,
      description: 'Dependency Proxy blobs.'

    field :dependency_proxy_image_count,
      GraphQL::Types::Int,
      null: false,
      description: 'Number of dependency proxy images cached in the group.'

    field :dependency_proxy_blob_count,
      GraphQL::Types::Int,
      null: false,
      description: 'Number of dependency proxy blobs cached in the group.'

    field :dependency_proxy_total_size,
      GraphQL::Types::String,
      null: false,
      description: 'Total size of the dependency proxy cached images.'

    field :dependency_proxy_total_size_in_bytes,
      GraphQL::Types::Int,
      null: false,
      deprecated: { reason: 'Use `dependencyProxyTotalSizeBytes`', milestone: '16.1' },
      description: 'Total size of the dependency proxy cached images in bytes.'

    field :dependency_proxy_total_size_bytes,
      GraphQL::Types::BigInt,
      null: false,
      description: 'Total size of the dependency proxy cached images in bytes, encoded as a string.'

    field :dependency_proxy_image_prefix,
      GraphQL::Types::String,
      null: false,
      description: 'Prefix for pulling images when using the dependency proxy.'

    field :dependency_proxy_image_ttl_policy,
      Types::DependencyProxy::ImageTtlGroupPolicyType,
      null: true,
      description: 'Dependency proxy TTL policy for the group.'

    field :labels,
      Types::LabelType.connection_type,
      null: true,
      description: 'Labels available on this group.',
      resolver: Resolvers::GroupLabelsResolver

    field :timelogs, ::Types::TimelogType.connection_type, null: false,
      description: 'Time logged on issues and merge requests in the group and its subgroups.',
      extras: [:lookahead],
      complexity: 5,
      resolver: ::Resolvers::TimelogResolver

    field :descendant_groups, Types::GroupType.connection_type,
      null: true,
      description: 'List of descendant groups of this group.',
      complexity: 5,
      resolver: Resolvers::NestedGroupsResolver

    field :descendant_groups_count,
      GraphQL::Types::Int,
      null: false,
      description: 'Count of direct descendant groups of this group.'

    field :group_members_count,
      GraphQL::Types::Int,
      null: false,
      description: 'Count of direct members of this group.'

    field :projects_count,
      GraphQL::Types::Int,
      null: false,
      description: 'Count of direct projects in this group.'

    field :ci_variables,
      Types::Ci::GroupVariableType.connection_type,
      null: true,
      description: "List of the group's CI/CD variables.",
      authorize: :admin_cicd_variables,
      resolver: Resolvers::Ci::VariablesResolver

    field :runners, Types::Ci::RunnerType.connection_type,
      null: true,
      resolver: Resolvers::Ci::GroupRunnersResolver,
      description: "Find runners visible to the current user."

    field :organizations, Types::CustomerRelations::OrganizationType.connection_type,
      null: true,
      description: "Find organizations of this group.",
      resolver: Resolvers::Crm::OrganizationsResolver

    field :organization_state_counts,
      Types::CustomerRelations::OrganizationStateCountsType,
      null: true,
      description: 'Counts of organizations by status for the group.',
      resolver: Resolvers::Crm::OrganizationStateCountsResolver

    field :contacts, Types::CustomerRelations::ContactType.connection_type,
      null: true,
      description: "Find contacts of this group.",
      resolver: Resolvers::Crm::ContactsResolver

    field :contact_state_counts,
      Types::CustomerRelations::ContactStateCountsType,
      null: true,
      description: 'Counts of contacts by state for the group.',
      resolver: Resolvers::Crm::ContactStateCountsResolver

    field :work_item_types, Types::WorkItems::TypeType.connection_type,
      resolver: Resolvers::WorkItems::TypesResolver,
      description: 'Work item types available to the group.'

    field :releases,
      Types::ReleaseType.connection_type,
      null: true,
      description: 'Releases belonging to projects in the group.',
      resolver: Resolvers::GroupReleasesResolver

    field :data_transfer, Types::DataTransfer::GroupDataTransferType,
      null: true,
      resolver: Resolvers::DataTransfer::GroupDataTransferResolver,
      description: 'Data transfer data point for a specific period. This is mocked data under a development feature flag.'

    field :work_items,
      null: true,
      description: 'Work items that belong to the namespace.',
      experiment: { milestone: '16.3' },
      resolver: ::Resolvers::Namespaces::WorkItemsResolver

    field :work_item, Types::WorkItemType,
      resolver: Resolvers::Namespaces::WorkItemResolver,
      experiment: { milestone: '16.4' },
      description: 'Find a work item by IID directly associated with the group. Returns `null` if the ' \
        '`namespace_level_work_items` feature flag is disabled.'

    field :work_item_state_counts,
      Types::WorkItemStateCountsType,
      null: true,
      experiment: { milestone: '16.7' },
      description: 'Counts of work items by state for the namespace. Returns `null` if the ' \
        '`namespace_level_work_items` feature flag is disabled.',
      resolver: Resolvers::Namespaces::WorkItemStateCountsResolver

    field :autocomplete_users,
      null: true,
      resolver: Resolvers::AutocompleteUsersResolver,
      description: 'Search users for autocompletion'

    field :lock_math_rendering_limits_enabled,
      GraphQL::Types::Boolean,
      null: true,
      method: :lock_math_rendering_limits_enabled?,
      description: 'Indicates if math rendering limits are locked for all descendant groups.'

    field :math_rendering_limits_enabled,
      GraphQL::Types::Boolean,
      null: true,
      method: :math_rendering_limits_enabled?,
      description: 'Indicates if math rendering limits are used for this group.'

    field :is_linked_to_subscription,
      GraphQL::Types::Boolean,
      null: true,
      method: :linked_to_subscription?,
      description: 'Indicates if group is linked to a subscription.'

    field :allowed_custom_statuses, Types::WorkItems::Widgets::CustomStatusType.connection_type,
      null: true, description: 'Allowed custom statuses for the group.',
      experiment: { milestone: '17.8' }, resolver: Resolvers::WorkItems::Widgets::CustomStatusResolver

    def label(title:)
      BatchLoader::GraphQL.for(title).batch(key: group) do |titles, loader, args|
        LabelsFinder
          .new(current_user, group: args[:key], title: titles)
          .execute
          .each { |label| loader.call(label.title, label) }
      end
    end

    def avatar_url
      object.avatar_url(only_path: false)
    end

    def parent
      Gitlab::Graphql::Loaders::BatchModelLoader.new(Group, object.parent_id).find
    end

    def container_repositories_count
      group.container_repositories.size
    end

    def dependency_proxy_manifests
      group.dependency_proxy_manifests.order_id_desc
    end

    def dependency_proxy_image_count
      group.dependency_proxy_manifests.size
    end

    def dependency_proxy_blob_count
      group.dependency_proxy_blobs.size
    end

    def dependency_proxy_total_size
      ActiveSupport::NumberHelper.number_to_human_size(
        dependency_proxy_total_size_in_bytes
      )
    end

    def dependency_proxy_total_size_in_bytes
      dependency_proxy_total_size_bytes
    end

    def dependency_proxy_total_size_bytes
      group.dependency_proxy_manifests.sum(:size) + group.dependency_proxy_blobs.sum(:size)
    end

    def dependency_proxy_setting
      group.dependency_proxy_setting || group.create_dependency_proxy_setting
    end

    def descendant_groups_count
      BatchLoader::GraphQL.for(object.id).batch do |group_ids, loader|
        descendants_counts = Group.id_in(group_ids).descendant_groups_counts
        descendants_counts.each { |group_id, count| loader.call(group_id, count) }
      end
    end

    def emails_disabled
      !group.emails_enabled?
    end

    def projects_count
      BatchLoader::GraphQL.for(object.id).batch do |group_ids, loader|
        projects_counts = Group.id_in(group_ids).projects_counts
        projects_counts.each { |group_id, count| loader.call(group_id, count) }
      end
    end

    def group_members_count
      BatchLoader::GraphQL.for(object.id).batch do |group_ids, loader|
        members_counts = Group.id_in(group_ids).group_members_counts
        members_counts.each { |group_id, count| loader.call(group_id, count) }
      end
    end

    def max_access_level
      return Gitlab::Access::NO_ACCESS if current_user.nil?

      BatchLoader::GraphQL.for(object.id).batch do |group_ids, loader|
        current_user.max_member_access_for_group_ids(group_ids).each do |group_id, max_access_level|
          loader.call(group_id, max_access_level)
        end
      end
    end

    def organization_edit_path
      return if group.organization.nil?

      ::Gitlab::Routing.url_helpers.edit_groups_organization_path(
        group.organization,
        id: group.to_param
      )
    end

    private

    def group
      object.respond_to?(:sync) ? object.sync : object
    end
  end
end

Types::GroupType.prepend_mod_with('Types::GroupType')
