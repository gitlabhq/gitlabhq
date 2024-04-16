# frozen_string_literal: true

module Types
  class NamespaceType < BaseObject
    graphql_name 'Namespace'

    authorize :read_namespace

    field :id, GraphQL::Types::ID, null: false,
                                   description: 'ID of the namespace.'

    field :full_name, GraphQL::Types::String, null: false,
                                              description: 'Full name of the namespace.'
    field :full_path, GraphQL::Types::ID, null: false,
                                          description: 'Full path of the namespace.'
    field :name, GraphQL::Types::String, null: false,
                                         description: 'Name of the namespace.'
    field :path, GraphQL::Types::String, null: false,
                                         description: 'Path of the namespace.'

    field :cross_project_pipeline_available,
          GraphQL::Types::Boolean,
          null: false,
          resolver_method: :cross_project_pipeline_available?,
          description: 'Indicates if the cross_project_pipeline feature is available for the namespace.'

    field :description, GraphQL::Types::String, null: true,
                                                description: 'Description of the namespace.'

    field :lfs_enabled,
          GraphQL::Types::Boolean,
          null: true,
          method: :lfs_enabled?,
          description: 'Indicates if Large File Storage (LFS) is enabled for namespace.'
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
                                                         description: 'Projects within this namespace.',
                                                         resolver: ::Resolvers::NamespaceProjectsResolver

    field :package_settings,
          Types::Namespace::PackageSettingsType,
          null: true,
          description: 'Package settings for the namespace.'

    field :shared_runners_setting,
          Types::Namespace::SharedRunnersSettingEnum,
          null: true,
          description: "Shared runners availability for the namespace and its descendants."

    field :timelog_categories,
          Types::TimeTracking::TimelogCategoryType.connection_type,
          null: true,
          description: "Timelog categories for the namespace.",
          alpha: { milestone: '15.3' }

    field :achievements,
          Types::Achievements::AchievementType.connection_type,
          null: true,
          alpha: { milestone: '15.8' },
          description: "Achievements for the namespace. " \
                       "Returns `null` if the `achievements` feature flag is disabled.",
          extras: [:lookahead],
          resolver: ::Resolvers::Achievements::AchievementsResolver

    field :work_item, Types::WorkItemType,
          null: true,
          resolver: Resolvers::Namespaces::WorkItemResolver,
          alpha: { milestone: '16.10' },
          description: 'Find a work item by IID directly associated with the namespace(project or group).  Returns ' \
                       '`null` for group level work items if the `namespace_level_work_items` feature flag is disabled.'

    markdown_field :description_html, null: true

    def timelog_categories
      object.timelog_categories if Feature.enabled?(:timelog_categories)
    end

    def cross_project_pipeline_available?
      object.licensed_feature_available?(:cross_project_pipelines)
    end

    def root_storage_statistics
      Gitlab::Graphql::Loaders::BatchRootStorageStatisticsLoader.new(object.id).find
    end
  end
end

Types::NamespaceType.prepend_mod_with('Types::NamespaceType')
