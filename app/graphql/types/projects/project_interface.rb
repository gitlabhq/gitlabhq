# frozen_string_literal: true

module Types
  module Projects
    # This interface sets [authorize: :read_project] (field-level authorization via
    # ProjectBaseField) for all defined fields to ensure implementing types don't
    # expose inherited fields without proper authorization.
    #
    # Implementing types can opt-out from this field-level auth and use
    # type-level auth by re-defining the field without the authorize argument.
    # For example, ProjectType uses :read_project type-level auth and redefines all
    # fields in this interface to opt-out while ProjectMinimalAccessType uses
    # :read_project_metadata type-level auth to expose a set of defined fields and
    # leaves inherited fields it does not want to expose to use field-level auth
    # using :read_project.
    module ProjectInterface
      prepend Gitlab::Graphql::MarkdownField
      include BaseInterface

      connection_type_class Types::CountableConnectionType

      graphql_name 'ProjectInterface'

      field_class ::Types::Projects::ProjectBaseField

      field :avatar_url, GraphQL::Types::String,
        null: true,
        calls_gitaly: true,
        description: 'Avatar URL of the project.'
      field :description, GraphQL::Types::String,
        null: true,
        description: 'Short description of the project.'
      field :full_path, GraphQL::Types::ID,
        null: true,
        description: 'Full path of the project.'
      # No, the quotes are not a typo. Used to get around circular dependencies.
      # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/27536#note_871009675
      field :group, 'Types::GroupType',
        null: true,
        description: 'Group of the project.'
      field :id, GraphQL::Types::ID, null: true,
        description: 'ID of the project.'
      field :name, GraphQL::Types::String,
        null: true,
        description: 'Name of the project without the namespace.'
      field :name_with_namespace, GraphQL::Types::String,
        null: true,
        description: 'Name of the project including the namespace.'
      field :path, GraphQL::Types::String,
        null: true,
        description: 'Path of the project.'
      field :repository, Types::RepositoryType,
        null: true,
        description: 'Git repository of the project.'
      field :user_permissions, Types::PermissionTypes::Project,
        description: 'Permissions for the current user on the project.',
        null: true,
        method: :itself
      field :web_url, GraphQL::Types::String,
        null: true,
        description: 'Web URL of the project.'
      field :visibility, GraphQL::Types::String,
        null: true,
        description: 'Visibility of the project.'

      field :ci_config_path_or_default, GraphQL::Types::String,
        null: true,
        description: 'Path of the CI configuration file.'

      field :organization_edit_path, GraphQL::Types::String,
        null: true,
        description: 'Path for editing project at the organization level.',
        experiment: { milestone: '16.11' }

      field :tag_list, GraphQL::Types::String,
        null: true,
        deprecated: { reason: 'Use `topics`', milestone: '13.12' },
        description: 'List of project topics (not Git tags).',
        method: :topic_list

      field :topics, [GraphQL::Types::String],
        null: true,
        description: 'List of project topics.',
        method: :topic_list

      field :http_url_to_repo, GraphQL::Types::String,
        null: true,
        description: 'URL to connect to the project via HTTPS.',
        scopes: [:api, :read_api, :ai_workflows]

      field :ssh_url_to_repo, GraphQL::Types::String,
        null: true,
        description: 'URL to connect to the project via SSH.',
        scopes: [:api, :read_api, :ai_workflows]

      field :forks_count, GraphQL::Types::Int,
        null: true,
        calls_gitaly: true, # 4 times
        description: 'Number of times the project has been forked.'

      field :star_count, GraphQL::Types::Int,
        null: true,
        description: 'Number of times the project has been starred.'

      field :created_at, Types::TimeType,
        null: true,
        description: 'Timestamp of the project creation.'

      field :updated_at, Types::TimeType,
        null: true,
        description: 'Timestamp of when the project was last updated.'

      field :last_activity_at, Types::TimeType,
        null: true,
        description: 'Timestamp of the project last activity.'

      field :archived, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates the archived status of the project.',
        method: :self_or_ancestors_archived?

      field :is_self_deletion_in_progress, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates if project deletion is in progress.',
        method: :self_deletion_in_progress?,
        experiment: { milestone: '18.3' }

      field :is_self_deletion_scheduled, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates if project deletion is scheduled.',
        method: :self_deletion_scheduled?,
        experiment: { milestone: '18.3' }

      field :marked_for_deletion, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates if the project or any ancestor is scheduled for deletion.',
        method: :scheduled_for_deletion_in_hierarchy_chain?,
        experiment: { milestone: '18.1' }

      field :marked_for_deletion_on, ::Types::TimeType,
        null: true,
        description: 'Date when project was scheduled to be deleted.',
        experiment: { milestone: '16.10' }

      field :permanent_deletion_date, GraphQL::Types::String,
        null: true,
        description: "For projects pending deletion, returns the project's scheduled deletion date. " \
          'For projects not pending deletion, returns a theoretical date based on current settings ' \
          'if marked for deletion today.',
        experiment: { milestone: '16.11' }

      field :lfs_enabled, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates if the project has Large File Storage (LFS) enabled.'

      field :merge_requests_ff_only_enabled, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates if no merge commits should be created and all merges should instead be ' \
          'fast-forwarded, which means that merging is only allowed if the branch could be fast-forwarded.'

      field :shared_runners_enabled, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates if shared runners are enabled for the project.'

      field :service_desk_enabled, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates if the project has Service Desk enabled.'

      field :service_desk_address, GraphQL::Types::String,
        null: true,
        description: 'E-mail address of the Service Desk.'

      field :jobs_enabled, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates if CI/CD pipeline jobs are enabled for the current user.'

      field :is_catalog_resource, GraphQL::Types::Boolean,
        experiment: { milestone: '15.11' },
        null: true,
        description: 'Indicates if a project is a catalog resource.'

      field :explore_catalog_path, GraphQL::Types::String,
        experiment: { milestone: '17.6' },
        null: true,
        description: 'Path to the project catalog resource.'

      field :public_jobs, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates if there is public access to pipelines and job details of the project, ' \
          'including output logs and artifacts.',
        method: :public_builds

      field :open_issues_count, GraphQL::Types::Int,
        null: true,
        description: 'Number of open issues for the project.'

      field :allow_merge_on_skipped_pipeline, GraphQL::Types::Boolean,
        null: true,
        description: 'If `only_allow_merge_if_pipeline_succeeds` is true, indicates if merge requests of ' \
          'the project can also be merged with skipped jobs.'

      field :autoclose_referenced_issues, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates if issues referenced by merge requests and commits within the default branch ' \
          'are closed automatically.'

      field :open_merge_requests_count, GraphQL::Types::Int,
        null: true,
        description: 'Number of open merge requests for the project.'

      field :import_status, GraphQL::Types::String,
        null: true,
        description: 'Status of import background job of the project.'

      field :jira_import_status, GraphQL::Types::String,
        null: true,
        description: 'Status of Jira import background job of the project.'

      field :only_allow_merge_if_all_discussions_are_resolved, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates if merge requests of the project can only be merged ' \
          'when all the discussions are resolved.'

      field :only_allow_merge_if_pipeline_succeeds, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates if merge requests of the project can only be merged with successful jobs.'

      field :printing_merge_request_link_enabled, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates if a link to create or view a merge request should display after a push to Git ' \
          'repositories of the project from the command line.'

      field :remove_source_branch_after_merge, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates if `Delete source branch` option should be enabled by default for all ' \
          'new merge requests of the project.'

      field :request_access_enabled, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates if users can request member access to the project.'

      field :squash_read_only, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates if `squashReadOnly` is enabled.',
        method: :squash_readonly?

      field :suggestion_commit_message, GraphQL::Types::String,
        null: true,
        description: 'Commit message used to apply merge request suggestions.'

      field :container_repositories_count, GraphQL::Types::Int,
        null: true,
        description: 'Number of container repositories in the project.'

      field :merge_commit_template, GraphQL::Types::String,
        null: true,
        description: 'Template used to create merge commit message in merge requests.'

      field :squash_commit_template, GraphQL::Types::String,
        null: true,
        description: 'Template used to create squash commit message in merge requests.'

      field :merge_request_title_regex, GraphQL::Types::String,
        null: true,
        description: 'Regex used to validate the title of merge requests.'

      field :merge_request_title_regex_description, GraphQL::Types::String,
        null: true,
        description: 'Description of the regex used to validate the title of merge requests.'

      field :allows_multiple_merge_request_assignees,
        GraphQL::Types::Boolean,
        method: :allows_multiple_merge_request_assignees?,
        description: 'Project allows assigning multiple users to a merge request.',
        null: true

      field :allows_multiple_merge_request_reviewers,
        GraphQL::Types::Boolean,
        method: :allows_multiple_merge_request_reviewers?,
        description: 'Project allows assigning multiple reviewers to a merge request.',
        null: true

      field :is_forked,
        GraphQL::Types::Boolean,
        resolver: Resolvers::Projects::IsForkedResolver,
        description: 'Project is forked.',
        null: true

      field :protectable_branches,
        [GraphQL::Types::String],
        description: 'List of unprotected branches, ignoring any wildcard branch rules.',
        null: true

      field :pages_force_https, GraphQL::Types::Boolean,
        null: true,
        description: "Project's Pages site redirects unsecured connections to HTTPS."

      field :pages_use_unique_domain, GraphQL::Types::Boolean,
        null: true,
        description: "Project's Pages site uses a unique subdomain."

      field :pipeline, Types::Ci::PipelineType,
        null: true,
        description: 'Pipeline of the project. If no arguments are provided, returns the latest pipeline for the ' \
          'head commit on the default branch',
        extras: [:lookahead],
        resolver: Resolvers::Ci::ProjectPipelineResolver

      field :jobs,
        type: Types::Ci::JobType.connection_type,
        null: true,
        description: 'Jobs of a project. This field can only be resolved for one project in any single request.'

      markdown_field :description_html, null: true

      {
        issues: "Issues are",
        merge_requests: "Merge requests are",
        wiki: 'Wikis are',
        snippets: 'Snippets are',
        container_registry: 'Container registry is'
      }.each do |feature, name_string|
        field "#{feature}_enabled", GraphQL::Types::Boolean, null: true,
          description: "Indicates if #{name_string} enabled for the current user"

        define_method :"#{feature}_enabled" do
          object.feature_available?(feature, context[:current_user]) # rubocop:disable Gitlab/FeatureAvailableUsage -- existing code
        end
      end

      def self.resolve_type(_object, _context)
        ::Types::ProjectType
      end

      def avatar_url
        object.avatar_url(only_path: false)
      end
    end
  end
end

Types::Projects::ProjectInterface.prepend_mod
