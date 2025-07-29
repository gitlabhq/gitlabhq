# frozen_string_literal: true

module Types
  class NamespaceType < BaseObject
    graphql_name 'Namespace'

    authorize :read_namespace

    def self.authorization_scopes
      super + [:ai_workflows]
    end

    implements Types::TodoableInterface
    expose_permissions Types::PermissionTypes::Namespaces::Base

    field :id, GraphQL::Types::ID, null: false,
      scopes: [:api, :read_api, :ai_workflows],
      description: 'ID of the namespace.'

    field :full_name, GraphQL::Types::String, null: false,
      description: 'Full name of the namespace.'
    field :full_path, GraphQL::Types::ID, null: false,
      scopes: [:api, :read_api, :ai_workflows],
      description: 'Full path of the namespace.'
    field :name, GraphQL::Types::String, null: false,
      scopes: [:api, :read_api, :ai_workflows],
      description: 'Name of the namespace.'
    field :path, GraphQL::Types::String, null: false,
      description: 'Path of the namespace.'

    field :cross_project_pipeline_available,
      GraphQL::Types::Boolean,
      null: false,
      resolver_method: :cross_project_pipeline_available?,
      description: 'Indicates if the cross_project_pipeline feature is available for the namespace.'

    field :description, GraphQL::Types::String, null: true,
      scopes: [:api, :read_api, :ai_workflows],
      description: 'Description of the namespace.'

    field :lfs_enabled,
      GraphQL::Types::Boolean,
      null: true,
      method: :lfs_enabled?,
      description: 'Indicates if Large File Storage (LFS) is enabled for namespace.'
    field :merge_requests_enabled,
      GraphQL::Types::Boolean,
      null: false,
      description: 'Indicates if merge requests are enabled for the namespace.',
      experiment: { milestone: '18.3' }
    field :request_access_enabled,
      GraphQL::Types::Boolean,
      null: true,
      description: 'Indicates if users can request access to namespace.'
    field :visibility, GraphQL::Types::String, null: true,
      description: 'Visibility of the namespace.'

    field :root_storage_statistics, Types::RootStorageStatisticsType,
      null: true,
      description: 'Aggregated storage statistics of the namespace. Only available for root namespaces.'

    field :projects, Types::ProjectType.connection_type, null: false,
      description: 'Projects within this namespace. ' \
        'Returns projects from the parent group if namespace is project.',
      resolver: ::Resolvers::NamespaceProjectsResolver

    field :package_settings,
      Types::Namespace::PackageSettingsType,
      null: true,
      description: 'Package settings for the namespace.'

    field :avatar_url, GraphQL::Types::String,
      null: true,
      description: 'URL to avatar image file of the namespace.'

    field :ci_cd_settings,
      Types::Ci::NamespaceSettingsType,
      null: true,
      experiment: { milestone: '17.9' },
      description: 'Namespace CI/CD settings for the namespace.',
      method: :namespace_settings

    field :shared_runners_setting,
      Types::Namespace::SharedRunnersSettingEnum,
      null: true,
      description: "Shared runners availability for the namespace and its descendants."

    field :timelog_categories,
      Types::TimeTracking::TimelogCategoryType.connection_type,
      null: true,
      description: "Timelog categories for the namespace.",
      experiment: { milestone: '15.3' }

    field :achievements,
      Types::Achievements::AchievementType.connection_type,
      null: true,
      experiment: { milestone: '15.8' },
      description: "Achievements for the namespace. " \
        "Returns `null` if the `achievements` feature flag is disabled.",
      extras: [:lookahead],
      resolver: ::Resolvers::Achievements::AchievementsResolver

    field :achievements_path, GraphQL::Types::String,
      null: true,
      experiment: { milestone: '17.0' },
      description: "Path for the namespace's achievements. " \
        "Returns `null` if the namespace is not a group, or the `achievements` feature flag is disabled."

    field :work_item, Types::WorkItemType,
      null: true,
      scopes: [:api, :read_api, :ai_workflows],
      resolver: Resolvers::Namespaces::WorkItemResolver,
      experiment: { milestone: '16.10' },
      description: 'Find a work item by IID directly associated with the namespace (project or group)'

    field :work_items,
      null: true,
      scopes: [:api, :read_api, :ai_workflows],
      description: 'Work items that belong to the namespace (project or group). Returns `null` for user namespaces.',
      experiment: { milestone: '18.1' },
      resolver: ::Resolvers::Namespaces::WorkItemsResolver

    field :work_item_state_counts,
      Types::WorkItemStateCountsType,
      null: true,
      experiment: { milestone: '18.3' },
      description: 'Counts of work items by state for the namespace (project or group). Returns `null` for user ' \
        'namespaces.',
      resolver: Resolvers::Namespaces::WorkItemStateCountsResolver

    field :work_items_widgets,
      null: true,
      description: 'List of available widgets for the given work items.',
      experiment: { milestone: '18.2' },
      resolver: ::Resolvers::WorkItems::WidgetsResolver

    field :work_item_types, Types::WorkItems::TypeType.connection_type,
      resolver: Resolvers::WorkItems::TypesResolver,
      experiment: { milestone: '17.2' },
      description: 'Work item types available to the namespace.'

    field :pages_deployments, Types::PagesDeploymentType.connection_type, null: true,
      resolver: Resolvers::PagesDeploymentsResolver,
      connection: true,
      description: "List of the namespaces's Pages Deployments."

    field :import_source_users, Import::SourceUserType.connection_type,
      null: true,
      experiment: { milestone: '17.2' },
      resolver: Resolvers::Import::SourceUsersResolver,
      description: 'Import source users of the namespace. This field can only be resolved for one namespace in any ' \
        'single request.' do
      extension(::Gitlab::Graphql::Limit::FieldCallCount, limit: 1)
    end

    field :sidebar,
      Types::Namespaces::SidebarType,
      null: true,
      description: 'Data needed to render the sidebar for the namespace.',
      method: :itself,
      experiment: { milestone: '17.6' }

    field :work_item_description_templates,
      Types::WorkItems::DescriptionTemplateType.connection_type,
      resolver: Resolvers::WorkItems::DescriptionTemplatesResolver,
      null: true, experiment: { milestone: '17.6' },
      calls_gitaly: true,
      description: 'Work item description templates available to the namespace.'

    field :link_paths,
      Types::Namespaces::LinkPaths,
      null: true,
      description: 'Namespace relevant paths to create links on the UI.',
      method: :itself,
      experiment: { milestone: '18.1' }

    field :markdown_paths,
      Types::Namespaces::MarkdownPaths,
      null: true,
      description: 'Namespace relevant paths to create markdown links on the UI.',
      method: :itself,
      experiment: { milestone: '18.1' }

    # TODO: Remove once the frontend switches to using available_features.
    # See: https://gitlab.com/gitlab-org/gitlab/-/issues/555803
    field :licensed_features,
      Types::Namespaces::AvailableFeaturesType,
      null: false,
      description: 'Licensed features available on the namespace.',
      method: :itself,
      experiment: { milestone: '18.1' }

    field :available_features,
      Types::Namespaces::AvailableFeaturesType,
      null: false,
      description: 'Features available on the namespace.',
      method: :itself,
      experiment: { milestone: '18.3' }

    field :web_url,
      GraphQL::Types::String,
      null: true,
      scopes: [:api, :read_api, :ai_workflows],
      description: 'URL of the namespace.'

    markdown_field :description_html, null: true, &:namespace_details

    def achievements_path
      return unless Feature.enabled?(:achievements, object)

      ::Gitlab::Routing.url_helpers.group_achievements_path(object) if object.is_a?(Group)
    end

    def timelog_categories
      object.timelog_categories if Feature.enabled?(:timelog_categories)
    end

    def cross_project_pipeline_available?
      object.licensed_feature_available?(:cross_project_pipelines)
    end

    def merge_requests_enabled
      return object.project.merge_requests_enabled? if object.is_a?(::Namespaces::ProjectNamespace)

      true
    end

    def root_storage_statistics
      Gitlab::Graphql::Loaders::BatchRootStorageStatisticsLoader.new(object.id).find
    end
  end
end

Types::NamespaceType.prepend_mod_with('Types::NamespaceType')
