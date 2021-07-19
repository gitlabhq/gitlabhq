# frozen_string_literal: true

module Types
  class ProjectType < BaseObject
    graphql_name 'Project'

    authorize :read_project

    expose_permissions Types::PermissionTypes::Project

    field :id, GraphQL::ID_TYPE, null: false,
          description: 'ID of the project.'

    field :full_path, GraphQL::ID_TYPE, null: false,
          description: 'Full path of the project.'
    field :path, GraphQL::STRING_TYPE, null: false,
          description: 'Path of the project.'

    field :sast_ci_configuration, Types::CiConfiguration::Sast::Type, null: true,
      calls_gitaly: true,
      description: 'SAST CI configuration for the project.'

    field :name_with_namespace, GraphQL::STRING_TYPE, null: false,
          description: 'Full name of the project with its namespace.'
    field :name, GraphQL::STRING_TYPE, null: false,
          description: 'Name of the project (without namespace).'

    field :description, GraphQL::STRING_TYPE, null: true,
          description: 'Short description of the project.'
    markdown_field :description_html, null: true

    field :tag_list, GraphQL::STRING_TYPE, null: true,
          deprecated: { reason: 'Use `topics`', milestone: '13.12' },
          description: 'List of project topics (not Git tags).'

    field :topics, [GraphQL::STRING_TYPE], null: true,
          description: 'List of project topics.'

    field :ssh_url_to_repo, GraphQL::STRING_TYPE, null: true,
          description: 'URL to connect to the project via SSH.'
    field :http_url_to_repo, GraphQL::STRING_TYPE, null: true,
          description: 'URL to connect to the project via HTTPS.'
    field :web_url, GraphQL::STRING_TYPE, null: true,
          description: 'Web URL of the project.'

    field :star_count, GraphQL::INT_TYPE, null: false,
          description: 'Number of times the project has been starred.'
    field :forks_count, GraphQL::INT_TYPE, null: false, calls_gitaly: true, # 4 times
          description: 'Number of times the project has been forked.'

    field :created_at, Types::TimeType, null: true,
          description: 'Timestamp of the project creation.'
    field :last_activity_at, Types::TimeType, null: true,
          description: 'Timestamp of the project last activity.'

    field :archived, GraphQL::BOOLEAN_TYPE, null: true,
          description: 'Indicates the archived status of the project.'

    field :visibility, GraphQL::STRING_TYPE, null: true,
          description: 'Visibility of the project.'

    field :shared_runners_enabled, GraphQL::BOOLEAN_TYPE, null: true,
          description: 'Indicates if shared runners are enabled for the project.'
    field :lfs_enabled, GraphQL::BOOLEAN_TYPE, null: true,
          description: 'Indicates if the project has Large File Storage (LFS) enabled.'
    field :merge_requests_ff_only_enabled, GraphQL::BOOLEAN_TYPE, null: true,
          description: 'Indicates if no merge commits should be created and all merges should instead be fast-forwarded, which means that merging is only allowed if the branch could be fast-forwarded.'

    field :service_desk_enabled, GraphQL::BOOLEAN_TYPE, null: true,
          description: 'Indicates if the project has service desk enabled.'

    field :service_desk_address, GraphQL::STRING_TYPE, null: true,
          description: 'E-mail address of the service desk.'

    field :avatar_url, GraphQL::STRING_TYPE, null: true, calls_gitaly: true,
          description: 'URL to avatar image file of the project.'

    {
      issues: "Issues are",
      merge_requests: "Merge Requests are",
      wiki: 'Wikis are',
      snippets: 'Snippets are',
      container_registry: 'Container Registry is'
    }.each do |feature, name_string|
      field "#{feature}_enabled", GraphQL::BOOLEAN_TYPE, null: true,
            description: "Indicates if #{name_string} enabled for the current user"

      define_method "#{feature}_enabled" do
        object.feature_available?(feature, context[:current_user])
      end
    end

    field :jobs_enabled, GraphQL::BOOLEAN_TYPE, null: true,
          description: 'Indicates if CI/CD pipeline jobs are enabled for the current user.'

    field :public_jobs, GraphQL::BOOLEAN_TYPE, method: :public_builds, null: true,
          description: 'Indicates if there is public access to pipelines and job details of the project, including output logs and artifacts.'

    field :open_issues_count, GraphQL::INT_TYPE, null: true,
          description: 'Number of open issues for the project.'

    field :import_status, GraphQL::STRING_TYPE, null: true,
          description: 'Status of import background job of the project.'
    field :jira_import_status, GraphQL::STRING_TYPE, null: true,
          description: 'Status of Jira import background job of the project.'
    field :only_allow_merge_if_pipeline_succeeds, GraphQL::BOOLEAN_TYPE, null: true,
          description: 'Indicates if merge requests of the project can only be merged with successful jobs.'
    field :allow_merge_on_skipped_pipeline, GraphQL::BOOLEAN_TYPE, null: true,
          description: 'If `only_allow_merge_if_pipeline_succeeds` is true, indicates if merge requests of the project can also be merged with skipped jobs.'
    field :request_access_enabled, GraphQL::BOOLEAN_TYPE, null: true,
          description: 'Indicates if users can request member access to the project.'
    field :only_allow_merge_if_all_discussions_are_resolved, GraphQL::BOOLEAN_TYPE, null: true,
          description: 'Indicates if merge requests of the project can only be merged when all the discussions are resolved.'
    field :printing_merge_request_link_enabled, GraphQL::BOOLEAN_TYPE, null: true,
          description: 'Indicates if a link to create or view a merge request should display after a push to Git repositories of the project from the command line.'
    field :remove_source_branch_after_merge, GraphQL::BOOLEAN_TYPE, null: true,
          description: 'Indicates if `Delete source branch` option should be enabled by default for all new merge requests of the project.'
    field :autoclose_referenced_issues, GraphQL::BOOLEAN_TYPE, null: true,
          description: 'Indicates if issues referenced by merge requests and commits within the default branch are closed automatically.'
    field :suggestion_commit_message, GraphQL::STRING_TYPE, null: true,
          description: 'The commit message used to apply merge request suggestions.'
    field :squash_read_only, GraphQL::BOOLEAN_TYPE, null: false, method: :squash_readonly?,
          description: 'Indicates if `squashReadOnly` is enabled.'

    field :namespace, Types::NamespaceType, null: true,
          description: 'Namespace of the project.'
    field :group, Types::GroupType, null: true,
          description: 'Group of the project.'

    field :statistics, Types::ProjectStatisticsType,
          null: true,
          description: 'Statistics of the project.'

    field :repository, Types::RepositoryType, null: true,
          description: 'Git repository of the project.'

    field :merge_requests,
          Types::MergeRequestType.connection_type,
          null: true,
          description: 'Merge requests of the project.',
          extras: [:lookahead],
          resolver: Resolvers::ProjectMergeRequestsResolver

    field :merge_request,
          Types::MergeRequestType,
          null: true,
          description: 'A single merge request of the project.',
          resolver: Resolvers::MergeRequestsResolver.single

    field :issues,
          Types::IssueType.connection_type,
          null: true,
          description: 'Issues of the project.',
          extras: [:lookahead],
          resolver: Resolvers::IssuesResolver

    field :issue_status_counts,
          Types::IssueStatusCountsType,
          null: true,
          description: 'Counts of issues by status for the project.',
          extras: [:lookahead],
          resolver: Resolvers::IssueStatusCountsResolver

    field :milestones, Types::MilestoneType.connection_type, null: true,
          description: 'Milestones of the project.',
          resolver: Resolvers::ProjectMilestonesResolver

    field :project_members,
          description: 'Members of the project.',
          resolver: Resolvers::ProjectMembersResolver

    field :environments,
          Types::EnvironmentType.connection_type,
          null: true,
          description: 'Environments of the project.',
          resolver: Resolvers::EnvironmentsResolver

    field :environment,
          Types::EnvironmentType,
          null: true,
          description: 'A single environment of the project.',
          resolver: Resolvers::EnvironmentsResolver.single

    field :issue,
          Types::IssueType,
          null: true,
          description: 'A single issue of the project.',
          resolver: Resolvers::IssuesResolver.single

    field :packages,
          description: 'Packages of the project.',
          resolver: Resolvers::ProjectPackagesResolver

    field :jobs,
          type: Types::Ci::JobType.connection_type,
          null: true,
          authorize: :read_commit_status,
          description: 'Jobs of a project. This field can only be resolved for one project in any single request.',
          resolver: Resolvers::ProjectJobsResolver

    field :pipelines,
          null: true,
          description: 'Build pipelines of the project.',
          extras: [:lookahead],
          resolver: Resolvers::ProjectPipelinesResolver

    field :pipeline,
          Types::Ci::PipelineType,
          null: true,
          description: 'Build pipeline of the project.',
          resolver: Resolvers::ProjectPipelineResolver

    field :ci_cd_settings,
          Types::Ci::CiCdSettingType,
          null: true,
          description: 'CI/CD settings for the project.'

    field :sentry_detailed_error,
          Types::ErrorTracking::SentryDetailedErrorType,
          null: true,
          description: 'Detailed version of a Sentry error on the project.',
          resolver: Resolvers::ErrorTracking::SentryDetailedErrorResolver

    field :grafana_integration,
          Types::GrafanaIntegrationType,
          null: true,
          description: 'Grafana integration details for the project.',
          resolver: Resolvers::Projects::GrafanaIntegrationResolver

    field :snippets,
          Types::SnippetType.connection_type,
          null: true,
          description: 'Snippets of the project.',
          resolver: Resolvers::Projects::SnippetsResolver

    field :sentry_errors,
          Types::ErrorTracking::SentryErrorCollectionType,
          null: true,
          description: 'Paginated collection of Sentry errors on the project.',
          resolver: Resolvers::ErrorTracking::SentryErrorCollectionResolver

    field :boards,
          Types::BoardType.connection_type,
          null: true,
          description: 'Boards of the project.',
          max_page_size: 2000,
          resolver: Resolvers::BoardsResolver

    field :board,
          Types::BoardType,
          null: true,
          description: 'A single board of the project.',
          resolver: Resolvers::BoardResolver

    field :jira_imports,
          Types::JiraImportType.connection_type,
          null: true,
          description: 'Jira imports into the project.'

    field :services,
          Types::Projects::ServiceType.connection_type,
          null: true,
          description: 'Project services.',
          resolver: Resolvers::Projects::ServicesResolver

    field :alert_management_alerts,
          Types::AlertManagement::AlertType.connection_type,
          null: true,
          description: 'Alert Management alerts of the project.',
          extras: [:lookahead],
          resolver: Resolvers::AlertManagement::AlertResolver

    field :alert_management_alert,
          Types::AlertManagement::AlertType,
          null: true,
          description: 'A single Alert Management alert of the project.',
          resolver: Resolvers::AlertManagement::AlertResolver.single

    field :alert_management_alert_status_counts,
          Types::AlertManagement::AlertStatusCountsType,
          null: true,
          description: 'Counts of alerts by status for the project.',
          resolver: Resolvers::AlertManagement::AlertStatusCountsResolver

    field :alert_management_integrations,
          Types::AlertManagement::IntegrationType.connection_type,
          null: true,
          description: 'Integrations which can receive alerts for the project.',
          resolver: Resolvers::AlertManagement::IntegrationsResolver

    field :alert_management_http_integrations,
          Types::AlertManagement::HttpIntegrationType.connection_type,
          null: true,
          description: 'HTTP Integrations which can receive alerts for the project.',
          resolver: Resolvers::AlertManagement::HttpIntegrationsResolver

    field :releases,
          Types::ReleaseType.connection_type,
          null: true,
          description: 'Releases of the project.',
          resolver: Resolvers::ReleasesResolver

    field :release,
          Types::ReleaseType,
          null: true,
          description: 'A single release of the project.',
          resolver: Resolvers::ReleasesResolver.single,
          authorize: :download_code

    field :container_expiration_policy,
          Types::ContainerExpirationPolicyType,
          null: true,
          description: 'The container expiration policy of the project.'

    field :container_repositories,
          Types::ContainerRepositoryType.connection_type,
          null: true,
          description: 'Container repositories of the project.',
          resolver: Resolvers::ContainerRepositoriesResolver

    field :container_repositories_count, GraphQL::INT_TYPE, null: false,
          description: 'Number of container repositories in the project.'

    field :label,
          Types::LabelType,
          null: true,
          description: 'A label available on this project.' do
            argument :title, GraphQL::STRING_TYPE,
              required: true,
              description: 'Title of the label.'
          end

    field :terraform_state,
          Types::Terraform::StateType,
          null: true,
          description: 'Find a single Terraform state by name.',
          resolver: Resolvers::Terraform::StatesResolver.single

    field :terraform_states,
          Types::Terraform::StateType.connection_type,
          null: true,
          description: 'Terraform states associated with the project.',
          resolver: Resolvers::Terraform::StatesResolver

    field :pipeline_analytics, Types::Ci::AnalyticsType, null: true,
          description: 'Pipeline analytics.',
          resolver: Resolvers::ProjectPipelineStatisticsResolver

    field :ci_template, Types::Ci::TemplateType, null: true,
          description: 'Find a single CI/CD template by name.',
          resolver: Resolvers::Ci::TemplateResolver

    field :ci_job_token_scope, Types::Ci::JobTokenScopeType, null: true,
          description: 'The CI Job Tokens scope of access.',
          resolver: Resolvers::Ci::JobTokenScopeResolver

    def label(title:)
      BatchLoader::GraphQL.for(title).batch(key: project) do |titles, loader, args|
        LabelsFinder
          .new(current_user, project: args[:key], title: titles)
          .execute
          .each { |label| loader.call(label.title, label) }
      end
    end

    field :labels,
          Types::LabelType.connection_type,
          null: true,
          description: 'Labels available on this project.',
          resolver: Resolvers::LabelsResolver

    def avatar_url
      object.avatar_url(only_path: false)
    end

    def jobs_enabled
      object.feature_available?(:builds, context[:current_user])
    end

    def open_issues_count
      object.open_issues_count if object.feature_available?(:issues, context[:current_user])
    end

    def statistics
      Gitlab::Graphql::Loaders::BatchProjectStatisticsLoader.new(object.id).find
    end

    def container_repositories_count
      project.container_repositories.size
    end

    def sast_ci_configuration
      return unless Ability.allowed?(current_user, :download_code, object)

      ::Security::CiConfiguration::SastParserService.new(object).configuration
    end

    def tag_list
      object.topic_list
    end

    private

    def project
      @project ||= object.respond_to?(:sync) ? object.sync : object
    end
  end
end

Types::ProjectType.prepend_mod_with('Types::ProjectType')
