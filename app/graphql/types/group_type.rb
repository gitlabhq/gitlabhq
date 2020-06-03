# frozen_string_literal: true

module Types
  class GroupType < NamespaceType
    graphql_name 'Group'

    authorize :read_group

    expose_permissions Types::PermissionTypes::Group

    field :web_url, GraphQL::STRING_TYPE, null: false,
          description: 'Web URL of the group'

    field :avatar_url, GraphQL::STRING_TYPE, null: true,
          description: 'Avatar URL of the group',
          resolve: -> (group, args, ctx) do
            group.avatar_url(only_path: false)
          end

    field :share_with_group_lock, GraphQL::BOOLEAN_TYPE, null: true,
          description: 'Indicates if sharing a project with another group within this group is prevented'

    field :project_creation_level, GraphQL::STRING_TYPE, null: true, method: :project_creation_level_str,
          description: 'The permission level required to create projects in the group'
    field :subgroup_creation_level, GraphQL::STRING_TYPE, null: true, method: :subgroup_creation_level_str,
          description: 'The permission level required to create subgroups within the group'

    field :require_two_factor_authentication, GraphQL::BOOLEAN_TYPE, null: true,
          description: 'Indicates if all users in this group are required to set up two-factor authentication'
    field :two_factor_grace_period, GraphQL::INT_TYPE, null: true,
          description: 'Time before two-factor authentication is enforced'

    field :auto_devops_enabled, GraphQL::BOOLEAN_TYPE, null: true,
          description: 'Indicates whether Auto DevOps is enabled for all projects within this group'

    field :emails_disabled, GraphQL::BOOLEAN_TYPE, null: true,
          description: 'Indicates if a group has email notifications disabled'

    field :mentions_disabled, GraphQL::BOOLEAN_TYPE, null: true,
          description: 'Indicates if a group is disabled from getting mentioned'

    field :parent, GroupType, null: true,
          description: 'Parent group',
          resolve: -> (obj, _args, _ctx) { Gitlab::Graphql::Loaders::BatchModelLoader.new(Group, obj.parent_id).find }

    field :issues,
          Types::IssueType.connection_type,
          null: true,
          description: 'Issues of the group',
          resolver: Resolvers::IssuesResolver

    field :milestones, Types::MilestoneType.connection_type, null: true,
          description: 'Find milestones',
          resolver: Resolvers::MilestoneResolver

    field :boards,
          Types::BoardType.connection_type,
          null: true,
          description: 'Boards of the group',
          max_page_size: 2000,
          resolver: Resolvers::BoardsResolver

    field :board,
          Types::BoardType,
          null: true,
          description: 'A single board of the group',
          resolver: Resolvers::BoardsResolver.single

    field :label,
          Types::LabelType,
          null: true,
          description: 'A label available on this group' do
            argument :title, GraphQL::STRING_TYPE,
              required: true,
              description: 'Title of the label'
          end

    def label(title:)
      BatchLoader::GraphQL.for(title).batch(key: group) do |titles, loader, args|
        LabelsFinder
          .new(current_user, group: args[:key], title: titles)
          .execute
          .each { |label| loader.call(label.title, label) }
      end
    end

    field :labels,
          Types::LabelType.connection_type,
          null: true,
          description: 'Labels available on this group' do
            argument :search_term, GraphQL::STRING_TYPE,
              required: false,
              description: 'A search term to find labels with'
          end

    def labels(search_term: nil)
      LabelsFinder
        .new(current_user, group: group, search: search_term)
        .execute
    end

    private

    def group
      object.respond_to?(:sync) ? object.sync : object
    end
  end
end

Types::GroupType.prepend_if_ee('EE::Types::GroupType')
