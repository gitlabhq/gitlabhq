module Types
  class ProjectType < BaseObject
    expose_permissions Types::PermissionTypes::Project

    graphql_name 'Project'

    field :id, GraphQL::ID_TYPE, null: false

    field :full_path, GraphQL::ID_TYPE, null: false
    field :path, GraphQL::STRING_TYPE, null: false

    field :name_with_namespace, GraphQL::STRING_TYPE, null: false
    field :name, GraphQL::STRING_TYPE, null: false

    field :description, GraphQL::STRING_TYPE, null: true

    field :default_branch, GraphQL::STRING_TYPE, null: true
    field :tag_list, GraphQL::STRING_TYPE, null: true

    field :ssh_url_to_repo, GraphQL::STRING_TYPE, null: true
    field :http_url_to_repo, GraphQL::STRING_TYPE, null: true
    field :web_url, GraphQL::STRING_TYPE, null: true

    field :star_count, GraphQL::INT_TYPE, null: false
    field :forks_count, GraphQL::INT_TYPE, null: false

    field :created_at, Types::TimeType, null: true
    field :last_activity_at, Types::TimeType, null: true

    field :archived, GraphQL::BOOLEAN_TYPE, null: true

    field :visibility, GraphQL::STRING_TYPE, null: true

    field :container_registry_enabled, GraphQL::BOOLEAN_TYPE, null: true
    field :shared_runners_enabled, GraphQL::BOOLEAN_TYPE, null: true
    field :lfs_enabled, GraphQL::BOOLEAN_TYPE, null: true
    field :merge_requests_ff_only_enabled, GraphQL::BOOLEAN_TYPE, null: true

    field :avatar_url, GraphQL::STRING_TYPE, null: true, resolve: -> (project, args, ctx) do
      project.avatar_url(only_path: false)
    end

    %i[issues merge_requests wiki snippets].each do |feature|
      field "#{feature}_enabled", GraphQL::BOOLEAN_TYPE, null: true, resolve: -> (project, args, ctx) do
        project.feature_available?(feature, ctx[:current_user])
      end
    end

    field :jobs_enabled, GraphQL::BOOLEAN_TYPE, null: true, resolve: -> (project, args, ctx) do
      project.feature_available?(:builds, ctx[:current_user])
    end

    field :public_jobs, GraphQL::BOOLEAN_TYPE, method: :public_builds, null: true

    field :open_issues_count, GraphQL::INT_TYPE, null: true, resolve: -> (project, args, ctx) do
      project.open_issues_count if project.feature_available?(:issues, ctx[:current_user])
    end

    field :import_status, GraphQL::STRING_TYPE, null: true
    field :ci_config_path, GraphQL::STRING_TYPE, null: true

    field :only_allow_merge_if_pipeline_succeeds, GraphQL::BOOLEAN_TYPE, null: true
    field :request_access_enabled, GraphQL::BOOLEAN_TYPE, null: true
    field :only_allow_merge_if_all_discussions_are_resolved, GraphQL::BOOLEAN_TYPE, null: true
    field :printing_merge_request_link_enabled, GraphQL::BOOLEAN_TYPE, null: true

    field :merge_request,
          Types::MergeRequestType,
          null: true,
          resolver: Resolvers::MergeRequestResolver do
      authorize :read_merge_request
    end

    field :pipelines,
          Types::Ci::PipelineType.connection_type,
          null: false,
          resolver: Resolvers::ProjectPipelinesResolver
  end
end
