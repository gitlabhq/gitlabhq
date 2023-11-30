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

    field :avatar_url,
          type: GraphQL::Types::String,
          null: true,
          description: 'Avatar URL of the group.'

    field :custom_emoji,
          type: Types::CustomEmojiType.connection_type,
          null: true,
          resolver: Resolvers::CustomEmojiResolver,
          description: 'Custom emoji in this namespace.',
          alpha: { milestone: '13.6' }

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
          authorize: :admin_group,
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
          Types::ContainerRepositoryType.connection_type,
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

    field :ci_variables,
          Types::Ci::GroupVariableType.connection_type,
          null: true,
          description: "List of the group's CI/CD variables.",
          authorize: :admin_group,
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
          alpha: { milestone: '16.3' },
          resolver: ::Resolvers::Namespaces::WorkItemsResolver

    field :work_item, Types::WorkItemType,
          resolver: Resolvers::Namespaces::WorkItemResolver,
          alpha: { milestone: '16.4' },
          description: 'Find a work item by IID directly associated with the group. Returns `null` if the ' \
                       '`namespace_level_work_items` feature flag is disabled.'

    field :autocomplete_users,
          null: true,
          resolver: Resolvers::AutocompleteUsersResolver,
          description: 'Search users for autocompletion'

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

    private

    def group
      object.respond_to?(:sync) ? object.sync : object
    end
  end
end

Types::GroupType.prepend_mod_with('Types::GroupType')
