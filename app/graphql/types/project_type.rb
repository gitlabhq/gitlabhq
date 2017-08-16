Types::ProjectType = GraphQL::ObjectType.define do
  name 'Project'

  field :id, !types.ID

  field :full_path, !types.ID
  field :path, !types.String

  field :name_with_namespace, !types.String
  field :name, !types.String

  field :description, types.String

  field :default_branch, types.String
  field :tag_list, types.String

  field :ssh_url_to_repo, types.String
  field :http_url_to_repo, types.String
  field :web_url, types.String

  field :star_count, !types.Int
  field :forks_count, !types.Int

  field :created_at, Types::TimeType
  field :last_activity_at, Types::TimeType

  field :archived, types.Boolean

  field :visibility, types.String

  field :container_registry_enabled, types.Boolean
  field :shared_runners_enabled, types.Boolean
  field :lfs_enabled, types.Boolean

  field :avatar_url, types.String do
    resolve ->(project, args, ctx) { project.avatar_url(only_path: false) }
  end

  %i[issues merge_requests wiki snippets].each do |feature|
    field "#{feature}_enabled", types.Boolean do
      resolve ->(project, args, ctx) { project.feature_available?(feature, ctx[:current_user]) }
    end
  end

  field :jobs_enabled, types.Boolean do
    resolve ->(project, args, ctx) { project.feature_available?(:builds, ctx[:current_user]) }
  end

  field :public_jobs, types.Boolean, property: :public_builds

  field :open_issues_count, types.Int do
    resolve ->(project, args, ctx) { project.open_issues_count if project.feature_available?(:issues, ctx[:current_user]) }
  end

  field :import_status, types.String
  field :ci_config_path, types.String

  field :only_allow_merge_if_pipeline_succeeds, types.Boolean
  field :request_access_enabled, types.Boolean
  field :only_allow_merge_if_all_discussions_are_resolved, types.Boolean
  field :printing_merge_request_link_enabled, types.Boolean
end
