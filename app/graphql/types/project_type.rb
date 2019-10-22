# frozen_string_literal: true

module Types
  class ProjectType < BaseObject
    graphql_name 'Project'

    authorize :read_project

    expose_permissions Types::PermissionTypes::Project

    field :id, GraphQL::ID_TYPE, null: false # rubocop:disable Graphql/Descriptions

    field :full_path, GraphQL::ID_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :path, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions

    field :name_with_namespace, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :name, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions

    field :description, GraphQL::STRING_TYPE, null: true # rubocop:disable Graphql/Descriptions
    markdown_field :description_html, null: true

    field :tag_list, GraphQL::STRING_TYPE, null: true # rubocop:disable Graphql/Descriptions

    field :ssh_url_to_repo, GraphQL::STRING_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :http_url_to_repo, GraphQL::STRING_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :web_url, GraphQL::STRING_TYPE, null: true # rubocop:disable Graphql/Descriptions

    field :star_count, GraphQL::INT_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :forks_count, GraphQL::INT_TYPE, null: false, calls_gitaly: true # 4 times # rubocop:disable Graphql/Descriptions

    field :created_at, Types::TimeType, null: true # rubocop:disable Graphql/Descriptions
    field :last_activity_at, Types::TimeType, null: true # rubocop:disable Graphql/Descriptions

    field :archived, GraphQL::BOOLEAN_TYPE, null: true # rubocop:disable Graphql/Descriptions

    field :visibility, GraphQL::STRING_TYPE, null: true # rubocop:disable Graphql/Descriptions

    field :container_registry_enabled, GraphQL::BOOLEAN_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :shared_runners_enabled, GraphQL::BOOLEAN_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :lfs_enabled, GraphQL::BOOLEAN_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :merge_requests_ff_only_enabled, GraphQL::BOOLEAN_TYPE, null: true # rubocop:disable Graphql/Descriptions

    field :avatar_url, GraphQL::STRING_TYPE, null: true, calls_gitaly: true, resolve: -> (project, args, ctx) do # rubocop:disable Graphql/Descriptions
      project.avatar_url(only_path: false)
    end

    %i[issues merge_requests wiki snippets].each do |feature|
      field "#{feature}_enabled", GraphQL::BOOLEAN_TYPE, null: true, resolve: -> (project, args, ctx) do # rubocop:disable Graphql/Descriptions
        project.feature_available?(feature, ctx[:current_user])
      end
    end

    field :jobs_enabled, GraphQL::BOOLEAN_TYPE, null: true, resolve: -> (project, args, ctx) do # rubocop:disable Graphql/Descriptions
      project.feature_available?(:builds, ctx[:current_user])
    end

    field :public_jobs, GraphQL::BOOLEAN_TYPE, method: :public_builds, null: true # rubocop:disable Graphql/Descriptions

    field :open_issues_count, GraphQL::INT_TYPE, null: true, resolve: -> (project, args, ctx) do # rubocop:disable Graphql/Descriptions
      project.open_issues_count if project.feature_available?(:issues, ctx[:current_user])
    end

    field :import_status, GraphQL::STRING_TYPE, null: true # rubocop:disable Graphql/Descriptions

    field :only_allow_merge_if_pipeline_succeeds, GraphQL::BOOLEAN_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :request_access_enabled, GraphQL::BOOLEAN_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :only_allow_merge_if_all_discussions_are_resolved, GraphQL::BOOLEAN_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :printing_merge_request_link_enabled, GraphQL::BOOLEAN_TYPE, null: true # rubocop:disable Graphql/Descriptions

    field :namespace, Types::NamespaceType, null: true # rubocop:disable Graphql/Descriptions
    field :group, Types::GroupType, null: true # rubocop:disable Graphql/Descriptions

    field :statistics, Types::ProjectStatisticsType, # rubocop:disable Graphql/Descriptions
          null: true,
          resolve: -> (obj, _args, _ctx) { Gitlab::Graphql::Loaders::BatchProjectStatisticsLoader.new(obj.id).find }

    field :repository, Types::RepositoryType, null: true # rubocop:disable Graphql/Descriptions

    field :merge_requests, # rubocop:disable Graphql/Descriptions
          Types::MergeRequestType.connection_type,
          null: true,
          resolver: Resolvers::MergeRequestsResolver

    field :merge_request, # rubocop:disable Graphql/Descriptions
          Types::MergeRequestType,
          null: true,
          resolver: Resolvers::MergeRequestsResolver.single

    field :issues, # rubocop:disable Graphql/Descriptions
          Types::IssueType.connection_type,
          null: true,
          resolver: Resolvers::IssuesResolver

    field :issue, # rubocop:disable Graphql/Descriptions
          Types::ExtendedIssueType,
          null: true,
          resolver: Resolvers::IssuesResolver.single

    field :pipelines, # rubocop:disable Graphql/Descriptions
          Types::Ci::PipelineType.connection_type,
          null: true,
          resolver: Resolvers::ProjectPipelinesResolver
  end
end
