# frozen_string_literal: true

module API
  module Entities
    class BlameRangeCommit < Grape::Entity
      expose :id
      expose :parent_ids
      expose :message
      expose :authored_date, :author_name, :author_email
      expose :committed_date, :committer_name, :committer_email
    end

    class BlameRange < Grape::Entity
      expose :commit, using: BlameRangeCommit
      expose :lines
    end

    class WikiPageBasic < Grape::Entity
      expose :format
      expose :slug
      expose :title
    end

    class WikiPage < WikiPageBasic
      expose :content
    end

    class WikiAttachment < Grape::Entity
      include Gitlab::FileMarkdownLinkBuilder

      expose :file_name
      expose :file_path
      expose :branch
      expose :link do
        expose :file_path, as: :url
        expose :markdown do |_entity|
          self.markdown_link
        end
      end

      def filename
        object.file_name
      end

      def secure_url
        object.file_path
      end
    end

    class UserSafe < Grape::Entity
      expose :id, :name, :username
    end

    class UserBasic < UserSafe
      expose :state

      expose :avatar_url do |user, options|
        user.avatar_url(only_path: false)
      end

      expose :avatar_path, if: ->(user, options) { options.fetch(:only_path, false) && user.avatar_path }
      expose :custom_attributes, using: 'API::Entities::CustomAttribute', if: :with_custom_attributes

      expose :web_url do |user, options|
        Gitlab::Routing.url_helpers.user_url(user)
      end
    end

    class User < UserBasic
      expose :created_at, if: ->(user, opts) { Ability.allowed?(opts[:current_user], :read_user_profile, user) }
      expose :bio, :location, :public_email, :skype, :linkedin, :twitter, :website_url, :organization
    end

    class UserActivity < Grape::Entity
      expose :username
      expose :last_activity_on
      expose :last_activity_on, as: :last_activity_at # Back-compat
    end

    class UserStarsProject < Grape::Entity
      expose :starred_since
      expose :user, using: Entities::UserBasic
    end

    class Identity < Grape::Entity
      expose :provider, :extern_uid
    end

    class UserPublic < User
      expose :last_sign_in_at
      expose :confirmed_at
      expose :last_activity_on
      expose :email
      expose :theme_id, :color_scheme_id, :projects_limit, :current_sign_in_at
      expose :identities, using: Entities::Identity
      expose :can_create_group?, as: :can_create_group
      expose :can_create_project?, as: :can_create_project
      expose :two_factor_enabled?, as: :two_factor_enabled
      expose :external
      expose :private_profile
    end

    class UserWithAdmin < UserPublic
      expose :admin?, as: :is_admin
    end

    class UserDetailsWithAdmin < UserWithAdmin
      expose :highest_role
    end

    class UserStatus < Grape::Entity
      expose :emoji
      expose :message
      expose :message_html do |entity|
        MarkupHelper.markdown_field(entity, :message)
      end
    end

    class Email < Grape::Entity
      expose :id, :email
    end

    class Hook < Grape::Entity
      expose :id, :url, :created_at, :push_events, :tag_push_events, :merge_requests_events, :repository_update_events
      expose :enable_ssl_verification
    end

    class ProjectHook < Hook
      expose :project_id, :issues_events, :confidential_issues_events
      expose :note_events, :confidential_note_events, :pipeline_events, :wiki_page_events
      expose :job_events
      expose :push_events_branch_filter
    end

    class SharedGroup < Grape::Entity
      expose :group_id
      expose :group_name do |group_link, options|
        group_link.group.name
      end
      expose :group_full_path do |group_link, options|
        group_link.group.full_path
      end
      expose :group_access, as: :group_access_level
      expose :expires_at
    end

    class ProjectIdentity < Grape::Entity
      expose :id, :description
      expose :name, :name_with_namespace
      expose :path, :path_with_namespace
      expose :created_at
    end

    class ProjectExportStatus < ProjectIdentity
      include ::API::Helpers::RelatedResourcesHelpers

      expose :export_status
      expose :_links, if: lambda { |project, _options| project.export_status == :finished } do
        expose :api_url do |project|
          expose_url(api_v4_projects_export_download_path(id: project.id))
        end

        expose :web_url do |project|
          Gitlab::Routing.url_helpers.download_export_project_url(project)
        end
      end
    end

    class RemoteMirror < Grape::Entity
      expose :id
      expose :enabled
      expose :safe_url, as: :url
      expose :update_status
      expose :last_update_at
      expose :last_update_started_at
      expose :last_successful_update_at
      expose :last_error
      expose :only_protected_branches
    end

    class ContainerExpirationPolicy < Grape::Entity
      expose :cadence
      expose :enabled
      expose :keep_n
      expose :older_than
      expose :name_regex
      expose :next_run_at
    end

    class ProjectImportStatus < ProjectIdentity
      expose :import_status

      # TODO: Use `expose_nil` once we upgrade the grape-entity gem
      expose :import_error, if: lambda { |project, _ops| project.import_state&.last_error } do |project|
        project.import_state.last_error
      end
    end

    class BasicProjectDetails < ProjectIdentity
      include ::API::ProjectsRelationBuilder

      expose :default_branch, if: -> (project, options) { Ability.allowed?(options[:current_user], :download_code, project) }
      # Avoids an N+1 query: https://github.com/mbleigh/acts-as-taggable-on/issues/91#issuecomment-168273770
      expose :tag_list do |project|
        # project.tags.order(:name).pluck(:name) is the most suitable option
        # to avoid loading all the ActiveRecord objects but, if we use it here
        # it override the preloaded associations and makes a query
        # (fixed in https://github.com/rails/rails/pull/25976).
        project.tags.map(&:name).sort
      end

      expose :ssh_url_to_repo, :http_url_to_repo, :web_url, :readme_url

      expose :license_url, if: :license do |project|
        license = project.repository.license_blob

        if license
          Gitlab::Routing.url_helpers.project_blob_url(project, File.join(project.default_branch, license.path))
        end
      end

      expose :license, with: 'API::Entities::LicenseBasic', if: :license do |project|
        project.repository.license
      end

      expose :avatar_url do |project, options|
        project.avatar_url(only_path: false)
      end

      expose :star_count, :forks_count
      expose :last_activity_at
      expose :namespace, using: 'API::Entities::NamespaceBasic'
      expose :custom_attributes, using: 'API::Entities::CustomAttribute', if: :with_custom_attributes

      # rubocop: disable CodeReuse/ActiveRecord
      def self.preload_relation(projects_relation, options = {})
        # Preloading tags, should be done with using only `:tags`,
        # as `:tags` are defined as: `has_many :tags, through: :taggings`
        # N+1 is solved then by using `subject.tags.map(&:name)`
        # MR describing the solution: https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/20555
        projects_relation.preload(:project_feature, :route)
                         .preload(:import_state, :tags)
                         .preload(:auto_devops)
                         .preload(namespace: [:route, :owner])
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end

    class Project < BasicProjectDetails
      include ::API::Helpers::RelatedResourcesHelpers

      expose :_links do
        expose :self do |project|
          expose_url(api_v4_projects_path(id: project.id))
        end

        expose :issues, if: -> (project, options) { issues_available?(project, options) } do |project|
          expose_url(api_v4_projects_issues_path(id: project.id))
        end

        expose :merge_requests, if: -> (project, options) { mrs_available?(project, options) } do |project|
          expose_url(api_v4_projects_merge_requests_path(id: project.id))
        end

        expose :repo_branches do |project|
          expose_url(api_v4_projects_repository_branches_path(id: project.id))
        end

        expose :labels do |project|
          expose_url(api_v4_projects_labels_path(id: project.id))
        end

        expose :events do |project|
          expose_url(api_v4_projects_events_path(id: project.id))
        end

        expose :members do |project|
          expose_url(api_v4_projects_members_path(id: project.id))
        end
      end

      expose :empty_repo?, as: :empty_repo
      expose :archived?, as: :archived
      expose :visibility
      expose :owner, using: Entities::UserBasic, unless: ->(project, options) { project.group }
      expose :resolve_outdated_diff_discussions
      expose :container_registry_enabled
      expose :container_expiration_policy, using: Entities::ContainerExpirationPolicy,
        if: -> (project, _) { project.container_expiration_policy }

      # Expose old field names with the new permissions methods to keep API compatible
      # TODO: remove in API v5, replaced by *_access_level
      expose(:issues_enabled) { |project, options| project.feature_available?(:issues, options[:current_user]) }
      expose(:merge_requests_enabled) { |project, options| project.feature_available?(:merge_requests, options[:current_user]) }
      expose(:wiki_enabled) { |project, options| project.feature_available?(:wiki, options[:current_user]) }
      expose(:jobs_enabled) { |project, options| project.feature_available?(:builds, options[:current_user]) }
      expose(:snippets_enabled) { |project, options| project.feature_available?(:snippets, options[:current_user]) }

      expose(:issues_access_level) { |project, options| project.project_feature.string_access_level(:issues) }
      expose(:repository_access_level) { |project, options| project.project_feature.string_access_level(:repository) }
      expose(:merge_requests_access_level) { |project, options| project.project_feature.string_access_level(:merge_requests) }
      expose(:wiki_access_level) { |project, options| project.project_feature.string_access_level(:wiki) }
      expose(:builds_access_level) { |project, options| project.project_feature.string_access_level(:builds) }
      expose(:snippets_access_level) { |project, options| project.project_feature.string_access_level(:snippets) }

      expose :shared_runners_enabled
      expose :lfs_enabled?, as: :lfs_enabled
      expose :creator_id
      expose :forked_from_project, using: Entities::BasicProjectDetails, if: ->(project, options) do
        project.forked? && Ability.allowed?(options[:current_user], :read_project, project.forked_from_project)
      end
      expose :import_status

      expose :import_error, if: lambda { |_project, options| options[:user_can_admin_project] } do |project|
        project.import_state&.last_error
      end

      expose :open_issues_count, if: lambda { |project, options| project.feature_available?(:issues, options[:current_user]) }
      expose :runners_token, if: lambda { |_project, options| options[:user_can_admin_project] }
      expose :ci_default_git_depth
      expose :public_builds, as: :public_jobs
      expose :build_git_strategy, if: lambda { |project, options| options[:user_can_admin_project] } do |project, options|
        project.build_allow_git_fetch ? 'fetch' : 'clone'
      end
      expose :build_timeout
      expose :auto_cancel_pending_pipelines
      expose :build_coverage_regex
      expose :ci_config_path, if: -> (project, options) { Ability.allowed?(options[:current_user], :download_code, project) }
      expose :shared_with_groups do |project, options|
        SharedGroup.represent(project.project_group_links, options)
      end
      expose :only_allow_merge_if_pipeline_succeeds
      expose :request_access_enabled
      expose :only_allow_merge_if_all_discussions_are_resolved
      expose :remove_source_branch_after_merge
      expose :printing_merge_request_link_enabled
      expose :merge_method
      expose :suggestion_commit_message
      expose :statistics, using: 'API::Entities::ProjectStatistics', if: -> (project, options) {
        options[:statistics] && Ability.allowed?(options[:current_user], :read_statistics, project)
      }
      expose :auto_devops_enabled?, as: :auto_devops_enabled
      expose :auto_devops_deploy_strategy do |project, options|
        project.auto_devops.nil? ? 'continuous' : project.auto_devops.deploy_strategy
      end
      expose :autoclose_referenced_issues

      # rubocop: disable CodeReuse/ActiveRecord
      def self.preload_relation(projects_relation, options = {})
        # Preloading tags, should be done with using only `:tags`,
        # as `:tags` are defined as: `has_many :tags, through: :taggings`
        # N+1 is solved then by using `subject.tags.map(&:name)`
        # MR describing the solution: https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/20555
        super(projects_relation).preload(:group)
                                .preload(:ci_cd_settings)
                                .preload(:container_expiration_policy)
                                .preload(:auto_devops)
                                .preload(project_group_links: { group: :route },
                                         fork_network: :root_project,
                                         fork_network_member: :forked_from_project,
                                         forked_from_project: [:route, :forks, :tags, namespace: :route])
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def self.forks_counting_projects(projects_relation)
        projects_relation + projects_relation.map(&:forked_from_project).compact
      end
    end

    class ProjectStatistics < Grape::Entity
      expose :commit_count
      expose :storage_size
      expose :repository_size
      expose :wiki_size
      expose :lfs_objects_size
      expose :build_artifacts_size, as: :job_artifacts_size
    end

    class ProjectDailyFetches < Grape::Entity
      expose :fetch_count, as: :count
      expose :date
    end

    class ProjectDailyStatistics < Grape::Entity
      expose :fetches do
        expose :total_fetch_count, as: :total
        expose :fetches, as: :days, using: ProjectDailyFetches
      end
    end

    class Member < Grape::Entity
      expose :user, merge: true, using: UserBasic
      expose :access_level
      expose :expires_at
    end

    class AccessRequester < Grape::Entity
      expose :user, merge: true, using: UserBasic
      expose :requested_at
    end

    class BasicGroupDetails < Grape::Entity
      expose :id
      expose :web_url
      expose :name
    end

    class Group < BasicGroupDetails
      expose :path, :description, :visibility
      expose :share_with_group_lock
      expose :require_two_factor_authentication
      expose :two_factor_grace_period
      expose :project_creation_level_str, as: :project_creation_level
      expose :auto_devops_enabled
      expose :subgroup_creation_level_str, as: :subgroup_creation_level
      expose :emails_disabled
      expose :lfs_enabled?, as: :lfs_enabled
      expose :avatar_url do |group, options|
        group.avatar_url(only_path: false)
      end
      expose :request_access_enabled
      expose :full_name, :full_path
      expose :parent_id

      expose :custom_attributes, using: 'API::Entities::CustomAttribute', if: :with_custom_attributes

      expose :statistics, if: :statistics do
        with_options format_with: -> (value) { value.to_i } do
          expose :storage_size
          expose :repository_size
          expose :wiki_size
          expose :lfs_objects_size
          expose :build_artifacts_size, as: :job_artifacts_size
        end
      end
    end

    class GroupDetail < Group
      expose :runners_token, if: lambda { |group, options| options[:user_can_admin_group] }
      expose :projects, using: Entities::Project do |group, options|
        projects = GroupProjectsFinder.new(
          group: group,
          current_user: options[:current_user],
          options: { only_owned: true, limit: projects_limit }
        ).execute

        Entities::Project.prepare_relation(projects)
      end

      expose :shared_projects, using: Entities::Project do |group, options|
        projects = GroupProjectsFinder.new(
          group: group,
          current_user: options[:current_user],
          options: { only_shared: true, limit: projects_limit }
        ).execute

        Entities::Project.prepare_relation(projects)
      end

      def projects_limit
        if ::Feature.enabled?(:limit_projects_in_groups_api, default_enabled: true)
          GroupProjectsFinder::DEFAULT_PROJECTS_LIMIT
        else
          nil
        end
      end
    end

    class DiffRefs < Grape::Entity
      expose :base_sha, :head_sha, :start_sha
    end

    class Commit < Grape::Entity
      expose :id, :short_id, :created_at
      expose :parent_ids
      expose :full_title, as: :title
      expose :safe_message, as: :message
      expose :author_name, :author_email, :authored_date
      expose :committer_name, :committer_email, :committed_date
    end

    class CommitStats < Grape::Entity
      expose :additions, :deletions, :total
    end

    class CommitWithStats < Commit
      expose :stats, using: Entities::CommitStats
    end

    class CommitDetail < Commit
      expose :stats, using: Entities::CommitStats, if: :stats
      expose :status
      expose :last_pipeline, using: 'API::Entities::PipelineBasic'
      expose :project_id
    end

    class CommitSignature < Grape::Entity
      expose :gpg_key_id
      expose :gpg_key_primary_keyid, :gpg_key_user_name, :gpg_key_user_email
      expose :verification_status
      expose :gpg_key_subkey_id
    end

    class BasicRef < Grape::Entity
      expose :type, :name
    end

    class Branch < Grape::Entity
      expose :name

      expose :commit, using: Entities::Commit do |repo_branch, options|
        options[:project].repository.commit(repo_branch.dereferenced_target)
      end

      expose :merged do |repo_branch, options|
        if options[:merged_branch_names]
          options[:merged_branch_names].include?(repo_branch.name)
        else
          options[:project].repository.merged_to_root_ref?(repo_branch)
        end
      end

      expose :protected do |repo_branch, options|
        ::ProtectedBranch.protected?(options[:project], repo_branch.name)
      end

      expose :developers_can_push do |repo_branch, options|
        ::ProtectedBranch.developers_can?(:push, repo_branch.name, protected_refs: options[:project].protected_branches)
      end

      expose :developers_can_merge do |repo_branch, options|
        ::ProtectedBranch.developers_can?(:merge, repo_branch.name, protected_refs: options[:project].protected_branches)
      end

      expose :can_push do |repo_branch, options|
        Gitlab::UserAccess.new(options[:current_user], project: options[:project]).can_push_to_branch?(repo_branch.name)
      end

      expose :default do |repo_branch, options|
        options[:project].default_branch == repo_branch.name
      end
    end

    class TreeObject < Grape::Entity
      expose :id, :name, :type, :path

      expose :mode do |obj, options|
        filemode = obj.mode
        filemode = "0" + filemode if filemode.length < 6
        filemode
      end
    end

    class Snippet < Grape::Entity
      expose :id, :title, :file_name, :description, :visibility
      expose :author, using: Entities::UserBasic
      expose :updated_at, :created_at
      expose :project_id
      expose :web_url do |snippet|
        Gitlab::UrlBuilder.build(snippet)
      end
    end

    class ProjectSnippet < Snippet
    end

    class PersonalSnippet < Snippet
      expose :raw_url do |snippet|
        Gitlab::UrlBuilder.build(snippet, raw: true)
      end
    end

    class IssuableEntity < Grape::Entity
      expose :id, :iid
      expose(:project_id) { |entity| entity&.project.try(:id) }
      expose :title, :description
      expose :state, :created_at, :updated_at

      # Avoids an N+1 query when metadata is included
      def issuable_metadata(subject, options, method, args = nil)
        cached_subject = options.dig(:issuable_metadata, subject.id)
        (cached_subject || subject).public_send(method, *args) # rubocop: disable GitlabSecurity/PublicSend
      end
    end

    class IssuableReferences < Grape::Entity
      expose :short do |issuable|
        issuable.to_reference
      end

      expose :relative do |issuable, options|
        issuable.to_reference(options[:group] || options[:project])
      end

      expose :full do |issuable|
        issuable.to_reference(full: true)
      end
    end

    class Diff < Grape::Entity
      expose :old_path, :new_path, :a_mode, :b_mode
      expose :new_file?, as: :new_file
      expose :renamed_file?, as: :renamed_file
      expose :deleted_file?, as: :deleted_file
      expose :json_safe_diff, as: :diff
    end

    class ProtectedRefAccess < Grape::Entity
      expose :access_level
      expose :access_level_description do |protected_ref_access|
        protected_ref_access.humanize
      end
    end

    class ProtectedBranch < Grape::Entity
      expose :name
      expose :push_access_levels, using: Entities::ProtectedRefAccess
      expose :merge_access_levels, using: Entities::ProtectedRefAccess
    end

    class ProtectedTag < Grape::Entity
      expose :name
      expose :create_access_levels, using: Entities::ProtectedRefAccess
    end

    class Milestone < Grape::Entity
      expose :id, :iid
      expose :project_id, if: -> (entity, options) { entity&.project_id }
      expose :group_id, if: -> (entity, options) { entity&.group_id }
      expose :title, :description
      expose :state, :created_at, :updated_at
      expose :due_date
      expose :start_date

      expose :web_url do |milestone, _options|
        Gitlab::UrlBuilder.build(milestone)
      end
    end

    class IssueBasic < IssuableEntity
      expose :closed_at
      expose :closed_by, using: Entities::UserBasic

      expose :labels do |issue, options|
        if options[:with_labels_details]
          ::API::Entities::LabelBasic.represent(issue.labels.sort_by(&:title))
        else
          issue.labels.map(&:title).sort
        end
      end

      expose :milestone, using: Entities::Milestone
      expose :assignees, :author, using: Entities::UserBasic

      expose :assignee, using: ::API::Entities::UserBasic do |issue|
        issue.assignees.first
      end

      expose(:user_notes_count)     { |issue, options| issuable_metadata(issue, options, :user_notes_count) }
      expose(:merge_requests_count) { |issue, options| issuable_metadata(issue, options, :merge_requests_count, options[:current_user]) }
      expose(:upvotes)              { |issue, options| issuable_metadata(issue, options, :upvotes) }
      expose(:downvotes)            { |issue, options| issuable_metadata(issue, options, :downvotes) }
      expose :due_date
      expose :confidential
      expose :discussion_locked

      expose :web_url do |issue|
        Gitlab::UrlBuilder.build(issue)
      end

      expose :time_stats, using: 'API::Entities::IssuableTimeStats' do |issue|
        issue
      end

      expose :task_completion_status
    end

    class Issue < IssueBasic
      include ::API::Helpers::RelatedResourcesHelpers

      expose(:has_tasks) do |issue, _|
        !issue.task_list_items.empty?
      end

      expose :task_status, if: -> (issue, _) do
        !issue.task_list_items.empty?
      end

      expose :_links do
        expose :self do |issue|
          expose_url(api_v4_project_issue_path(id: issue.project_id, issue_iid: issue.iid))
        end

        expose :notes do |issue|
          expose_url(api_v4_projects_issues_notes_path(id: issue.project_id, noteable_id: issue.iid))
        end

        expose :award_emoji do |issue|
          expose_url(api_v4_projects_issues_award_emoji_path(id: issue.project_id, issue_iid: issue.iid))
        end

        expose :project do |issue|
          expose_url(api_v4_projects_path(id: issue.project_id))
        end
      end

      expose :references, with: IssuableReferences do |issue|
        issue
      end

      # Calculating the value of subscribed field triggers Markdown
      # processing. We can't do that for multiple issues / merge
      # requests in a single API request.
      expose :subscribed, if: -> (_, options) { options.fetch(:include_subscribed, true) } do |issue, options|
        issue.subscribed?(options[:current_user], options[:project] || issue.project)
      end

      expose :moved_to_id
    end

    class IssuableTimeStats < Grape::Entity
      format_with(:time_tracking_formatter) do |time_spent|
        Gitlab::TimeTrackingFormatter.output(time_spent)
      end

      expose :time_estimate
      expose :total_time_spent
      expose :human_time_estimate

      with_options(format_with: :time_tracking_formatter) do
        expose :total_time_spent, as: :human_total_time_spent
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def total_time_spent
        # Avoids an N+1 query since timelogs are preloaded
        object.timelogs.map(&:time_spent).sum
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end

    class ExternalIssue < Grape::Entity
      expose :title
      expose :id
    end

    class PipelineBasic < Grape::Entity
      expose :id, :sha, :ref, :status
      expose :created_at, :updated_at

      expose :web_url do |pipeline, _options|
        Gitlab::Routing.url_helpers.project_pipeline_url(pipeline.project, pipeline)
      end
    end

    class MergeRequestSimple < IssuableEntity
      expose :title
      expose :web_url do |merge_request, options|
        Gitlab::UrlBuilder.build(merge_request)
      end
    end

    class MergeRequestBasic < IssuableEntity
      expose :merged_by, using: Entities::UserBasic do |merge_request, _options|
        merge_request.metrics&.merged_by
      end

      expose :merged_at do |merge_request, _options|
        merge_request.metrics&.merged_at
      end

      expose :closed_by, using: Entities::UserBasic do |merge_request, _options|
        merge_request.metrics&.latest_closed_by
      end

      expose :closed_at do |merge_request, _options|
        merge_request.metrics&.latest_closed_at
      end

      expose :title_html, if: -> (_, options) { options[:render_html] } do |entity|
        MarkupHelper.markdown_field(entity, :title)
      end
      expose :description_html, if: -> (_, options) { options[:render_html] } do |entity|
        MarkupHelper.markdown_field(entity, :description)
      end
      expose :target_branch, :source_branch
      expose(:user_notes_count) { |merge_request, options| issuable_metadata(merge_request, options, :user_notes_count) }
      expose(:upvotes)          { |merge_request, options| issuable_metadata(merge_request, options, :upvotes) }
      expose(:downvotes)        { |merge_request, options| issuable_metadata(merge_request, options, :downvotes) }
      expose :assignee, using: ::API::Entities::UserBasic do |merge_request|
        merge_request.assignee
      end
      expose :author, :assignees, using: Entities::UserBasic

      expose :source_project_id, :target_project_id
      expose :labels do |merge_request, options|
        if options[:with_labels_details]
          ::API::Entities::LabelBasic.represent(merge_request.labels.sort_by(&:title))
        else
          merge_request.labels.map(&:title).sort
        end
      end
      expose :work_in_progress?, as: :work_in_progress
      expose :milestone, using: Entities::Milestone
      expose :merge_when_pipeline_succeeds

      # Ideally we should deprecate `MergeRequest#merge_status` exposure and
      # use `MergeRequest#mergeable?` instead (boolean).
      # See https://gitlab.com/gitlab-org/gitlab-foss/issues/42344 for more
      # information.
      expose :merge_status do |merge_request|
        merge_request.check_mergeability
        merge_request.merge_status
      end
      expose :diff_head_sha, as: :sha
      expose :merge_commit_sha
      expose :squash_commit_sha
      expose :discussion_locked
      expose :should_remove_source_branch?, as: :should_remove_source_branch
      expose :force_remove_source_branch?, as: :force_remove_source_branch
      expose :allow_collaboration, if: -> (merge_request, _) { merge_request.for_fork? }
      # Deprecated
      expose :allow_collaboration, as: :allow_maintainer_to_push, if: -> (merge_request, _) { merge_request.for_fork? }

      # reference is deprecated in favour of references
      # Introduced [Gitlab 12.6](https://gitlab.com/gitlab-org/gitlab/merge_requests/20354)
      expose :reference do |merge_request, options|
        merge_request.to_reference(options[:project])
      end

      expose :references, with: IssuableReferences do |merge_request|
        merge_request
      end

      expose :web_url do |merge_request|
        Gitlab::UrlBuilder.build(merge_request)
      end

      expose :time_stats, using: 'API::Entities::IssuableTimeStats' do |merge_request|
        merge_request
      end

      expose :squash

      expose :task_completion_status

      expose :cannot_be_merged?, as: :has_conflicts

      expose :mergeable_discussions_state?, as: :blocking_discussions_resolved
    end

    class MergeRequest < MergeRequestBasic
      expose :subscribed, if: -> (_, options) { options.fetch(:include_subscribed, true) } do |merge_request, options|
        merge_request.subscribed?(options[:current_user], options[:project])
      end

      expose :changes_count do |merge_request, _options|
        merge_request.merge_request_diff.real_size
      end

      expose :latest_build_started_at, if: -> (_, options) { build_available?(options) } do |merge_request, _options|
        merge_request.metrics&.latest_build_started_at
      end

      expose :latest_build_finished_at, if: -> (_, options) { build_available?(options) } do |merge_request, _options|
        merge_request.metrics&.latest_build_finished_at
      end

      expose :first_deployed_to_production_at, if: -> (_, options) { build_available?(options) } do |merge_request, _options|
        merge_request.metrics&.first_deployed_to_production_at
      end

      expose :pipeline, using: Entities::PipelineBasic, if: -> (_, options) { build_available?(options) } do |merge_request, _options|
        merge_request.metrics&.pipeline
      end

      expose :head_pipeline, using: 'API::Entities::Pipeline', if: -> (_, options) do
        Ability.allowed?(options[:current_user], :read_pipeline, options[:project])
      end

      expose :diff_refs, using: Entities::DiffRefs

      # Allow the status of a rebase to be determined
      expose :merge_error
      expose :rebase_in_progress?, as: :rebase_in_progress, if: -> (_, options) { options[:include_rebase_in_progress] }

      expose :diverged_commits_count, as: :diverged_commits_count, if: -> (_, options) { options[:include_diverged_commits_count] }

      def build_available?(options)
        options[:project]&.feature_available?(:builds, options[:current_user])
      end

      expose :user do
        expose :can_merge do |merge_request, options|
          merge_request.can_be_merged_by?(options[:current_user])
        end
      end
    end

    class MergeRequestChanges < MergeRequest
      expose :diffs, as: :changes, using: Entities::Diff do |compare, _|
        compare.raw_diffs(limits: false).to_a
      end
    end

    class MergeRequestDiff < Grape::Entity
      expose :id, :head_commit_sha, :base_commit_sha, :start_commit_sha,
        :created_at, :merge_request_id, :state, :real_size
    end

    class MergeRequestDiffFull < MergeRequestDiff
      expose :commits, using: Entities::Commit

      expose :diffs, using: Entities::Diff do |compare, _|
        compare.raw_diffs(limits: false).to_a
      end
    end

    class SSHKey < Grape::Entity
      expose :id, :title, :key, :created_at
    end

    class SSHKeyWithUser < SSHKey
      expose :user, using: Entities::UserPublic
    end

    class DeployKeyWithUser < SSHKeyWithUser
      expose :deploy_keys_projects
    end

    class DeployKeysProject < Grape::Entity
      expose :deploy_key, merge: true, using: Entities::SSHKey
      expose :can_push
    end

    class GPGKey < Grape::Entity
      expose :id, :key, :created_at
    end

    class DiffPosition < Grape::Entity
      expose :base_sha, :start_sha, :head_sha, :old_path, :new_path,
        :position_type
    end

    class Note < Grape::Entity
      # Only Issue and MergeRequest have iid
      NOTEABLE_TYPES_WITH_IID = %w(Issue MergeRequest).freeze

      expose :id
      expose :type
      expose :note, as: :body
      expose :attachment_identifier, as: :attachment
      expose :author, using: Entities::UserBasic
      expose :created_at, :updated_at
      expose :system?, as: :system
      expose :noteable_id, :noteable_type

      expose :position, if: ->(note, options) { note.is_a?(DiffNote) } do |note|
        note.position.to_h
      end

      expose :resolvable?, as: :resolvable
      expose :resolved?, as: :resolved, if: ->(note, options) { note.resolvable? }
      expose :resolved_by, using: Entities::UserBasic, if: ->(note, options) { note.resolvable? }

      # Avoid N+1 queries as much as possible
      expose(:noteable_iid) { |note| note.noteable.iid if NOTEABLE_TYPES_WITH_IID.include?(note.noteable_type) }
    end

    class Discussion < Grape::Entity
      expose :id
      expose :individual_note?, as: :individual_note
      expose :notes, using: Entities::Note
    end

    class Avatar < Grape::Entity
      expose :avatar_url do |avatarable, options|
        avatarable.avatar_url(only_path: false, size: options[:size])
      end
    end

    class AwardEmoji < Grape::Entity
      expose :id
      expose :name
      expose :user, using: Entities::UserBasic
      expose :created_at, :updated_at
      expose :awardable_id, :awardable_type
    end

    class MRNote < Grape::Entity
      expose :note
      expose :author, using: Entities::UserBasic
    end

    class CommitNote < Grape::Entity
      expose :note
      expose(:path) { |note| note.diff_file.try(:file_path) if note.diff_note? }
      expose(:line) { |note| note.diff_line.try(:new_line) if note.diff_note? }
      expose(:line_type) { |note| note.diff_line.try(:type) if note.diff_note? }
      expose :author, using: Entities::UserBasic
      expose :created_at
    end

    class CommitStatus < Grape::Entity
      expose :id, :sha, :ref, :status, :name, :target_url, :description,
             :created_at, :started_at, :finished_at, :allow_failure, :coverage
      expose :author, using: Entities::UserBasic
    end

    class PushEventPayload < Grape::Entity
      expose :commit_count, :action, :ref_type, :commit_from, :commit_to, :ref,
             :commit_title, :ref_count
    end

    class Event < Grape::Entity
      expose :project_id, :action_name
      expose :target_id, :target_iid, :target_type, :author_id
      expose :target_title
      expose :created_at
      expose :note, using: Entities::Note, if: ->(event, options) { event.note? }
      expose :author, using: Entities::UserBasic, if: ->(event, options) { event.author }

      expose :push_event_payload,
        as: :push_data,
        using: PushEventPayload,
        if: -> (event, _) { event.push_action? }

      expose :author_username do |event, options|
        event.author&.username
      end
    end

    class ProjectGroupLink < Grape::Entity
      expose :id, :project_id, :group_id, :group_access, :expires_at
    end

    class Todo < Grape::Entity
      expose :id
      expose :project, using: Entities::ProjectIdentity, if: -> (todo, _) { todo.project_id }
      expose :group, using: 'API::Entities::NamespaceBasic', if: -> (todo, _) { todo.group_id }
      expose :author, using: Entities::UserBasic
      expose :action_name
      expose :target_type

      expose :target do |todo, options|
        todo_options = options.fetch(todo.target_type, {})
        todo_target_class(todo.target_type).represent(todo.target, todo_options)
      end

      expose :target_url do |todo, options|
        todo_target_url(todo)
      end

      expose :body
      expose :state
      expose :created_at

      def todo_target_class(target_type)
        # false as second argument prevents looking up in module hierarchy
        # see also https://gitlab.com/gitlab-org/gitlab-foss/issues/59719
        ::API::Entities.const_get(target_type, false)
      end

      def todo_target_url(todo)
        target_type = todo.target_type.underscore
        target_url = "#{todo.resource_parent.class.to_s.underscore}_#{target_type}_url"

        Gitlab::Routing
          .url_helpers
          .public_send(target_url, todo.resource_parent, todo.target, anchor: todo_target_anchor(todo)) # rubocop:disable GitlabSecurity/PublicSend
      end

      def todo_target_anchor(todo)
        "note_#{todo.note_id}" if todo.note_id?
      end
    end

    class NamespaceBasic < Grape::Entity
      expose :id, :name, :path, :kind, :full_path, :parent_id, :avatar_url

      expose :web_url do |namespace|
        if namespace.user?
          Gitlab::Routing.url_helpers.user_url(namespace.owner)
        else
          namespace.web_url
        end
      end
    end

    class Namespace < NamespaceBasic
      expose :members_count_with_descendants, if: -> (namespace, opts) { expose_members_count_with_descendants?(namespace, opts) } do |namespace, _|
        namespace.users_with_descendants.count
      end

      def expose_members_count_with_descendants?(namespace, opts)
        namespace.kind == 'group' && Ability.allowed?(opts[:current_user], :admin_group, namespace)
      end
    end

    class MemberAccess < Grape::Entity
      expose :access_level
      expose :notification_level do |member, options|
        if member.notification_setting
          ::NotificationSetting.levels[member.notification_setting.level]
        end
      end
    end

    class ProjectAccess < MemberAccess
    end

    class GroupAccess < MemberAccess
    end

    class NotificationSetting < Grape::Entity
      expose :level
      expose :events, if: ->(notification_setting, _) { notification_setting.custom? } do
        ::NotificationSetting.email_events.each do |event|
          expose event
        end
      end
    end

    class GlobalNotificationSetting < NotificationSetting
      expose :notification_email do |notification_setting, options|
        notification_setting.user.notification_email
      end
    end

    class ProjectServiceBasic < Grape::Entity
      expose :id, :title, :created_at, :updated_at, :active
      expose :commit_events, :push_events, :issues_events, :confidential_issues_events
      expose :merge_requests_events, :tag_push_events, :note_events
      expose :confidential_note_events, :pipeline_events, :wiki_page_events
      expose :job_events, :comment_on_event_enabled
    end

    class ProjectService < ProjectServiceBasic
      # Expose serialized properties
      expose :properties do |service, options|
        # TODO: Simplify as part of https://gitlab.com/gitlab-org/gitlab/issues/29404
        if service.data_fields_present?
          service.data_fields.as_json.slice(*service.api_field_names)
        else
          service.properties.slice(*service.api_field_names)
        end
      end
    end

    class ProjectWithAccess < Project
      expose :permissions do
        expose :project_access, using: Entities::ProjectAccess do |project, options|
          if options[:project_members]
            options[:project_members].find { |member| member.source_id == project.id }
          else
            project.project_member(options[:current_user])
          end
        end

        expose :group_access, using: Entities::GroupAccess do |project, options|
          if project.group
            if options[:group_members]
              options[:group_members].find { |member| member.source_id == project.namespace_id }
            else
              project.group.highest_group_member(options[:current_user])
            end
          end
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def self.preload_relation(projects_relation, options = {})
        relation = super(projects_relation, options)
        project_ids = relation.select('projects.id')
        namespace_ids = relation.select(:namespace_id)

        options[:project_members] = options[:current_user]
          .project_members
          .where(source_id: project_ids)
          .preload(:source, user: [notification_settings: :source])

        options[:group_members] = options[:current_user]
          .group_members
          .where(source_id: namespace_ids)
          .preload(:source, user: [notification_settings: :source])

        relation
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end

    class LabelBasic < Grape::Entity
      expose :id, :name, :color, :description, :description_html, :text_color
    end

    class Label < LabelBasic
      with_options if: lambda { |_, options| options[:with_counts] } do
        expose :open_issues_count do |label, options|
          label.open_issues_count(options[:current_user])
        end

        expose :closed_issues_count do |label, options|
          label.closed_issues_count(options[:current_user])
        end

        expose :open_merge_requests_count do |label, options|
          label.open_merge_requests_count(options[:current_user])
        end
      end

      expose :subscribed do |label, options|
        label.subscribed?(options[:current_user], options[:parent])
      end
    end

    class GroupLabel < Label
    end

    class ProjectLabel < Label
      expose :priority do |label, options|
        label.priority(options[:parent])
      end
      expose :is_project_label do |label, options|
        label.is_a?(::ProjectLabel)
      end
    end

    class List < Grape::Entity
      expose :id
      expose :label, using: Entities::LabelBasic
      expose :position
    end

    class Board < Grape::Entity
      expose :id
      expose :project, using: Entities::BasicProjectDetails

      expose :lists, using: Entities::List do |board|
        board.destroyable_lists
      end
    end

    class Compare < Grape::Entity
      expose :commit, using: Entities::Commit do |compare, options|
        ::Commit.decorate(compare.commits, nil).last
      end

      expose :commits, using: Entities::Commit do |compare, options|
        ::Commit.decorate(compare.commits, nil)
      end

      expose :diffs, using: Entities::Diff do |compare, options|
        compare.diffs(limits: false).to_a
      end

      expose :compare_timeout do |compare, options|
        compare.diffs.overflow?
      end

      expose :same, as: :compare_same_ref
    end

    class Contributor < Grape::Entity
      expose :name, :email, :commits, :additions, :deletions
    end

    class BroadcastMessage < Grape::Entity
      expose :message, :starts_at, :ends_at, :color, :font, :target_path
    end

    class ApplicationStatistics < Grape::Entity
      include ActionView::Helpers::NumberHelper
      include CountHelper

      expose :forks do |counts|
        approximate_fork_count_with_delimiters(counts)
      end

      expose :issues do |counts|
        approximate_count_with_delimiters(counts, ::Issue)
      end

      expose :merge_requests do |counts|
        approximate_count_with_delimiters(counts, ::MergeRequest)
      end

      expose :notes do |counts|
        approximate_count_with_delimiters(counts, ::Note)
      end

      expose :snippets do |counts|
        approximate_count_with_delimiters(counts, ::Snippet)
      end

      expose :ssh_keys do |counts|
        approximate_count_with_delimiters(counts, ::Key)
      end

      expose :milestones do |counts|
        approximate_count_with_delimiters(counts, ::Milestone)
      end

      expose :users do |counts|
        approximate_count_with_delimiters(counts, ::User)
      end

      expose :projects do |counts|
        approximate_count_with_delimiters(counts, ::Project)
      end

      expose :groups do |counts|
        approximate_count_with_delimiters(counts, ::Group)
      end

      expose :active_users do |_|
        number_with_delimiter(::User.active.count)
      end
    end

    class ApplicationSetting < Grape::Entity
      def self.exposed_attributes
        attributes = ::ApplicationSettingsHelper.visible_attributes
        attributes.delete(:performance_bar_allowed_group_path)
        attributes.delete(:performance_bar_enabled)
        attributes.delete(:allow_local_requests_from_hooks_and_services)

        # let's not expose the secret key in a response
        attributes.delete(:asset_proxy_secret_key)
        attributes.delete(:eks_secret_access_key)

        attributes
      end

      expose :id, :performance_bar_allowed_group_id
      expose(*exposed_attributes)
      expose(:restricted_visibility_levels) do |setting, _options|
        setting.restricted_visibility_levels.map { |level| Gitlab::VisibilityLevel.string_level(level) }
      end
      expose(:default_project_visibility) { |setting, _options| Gitlab::VisibilityLevel.string_level(setting.default_project_visibility) }
      expose(:default_snippet_visibility) { |setting, _options| Gitlab::VisibilityLevel.string_level(setting.default_snippet_visibility) }
      expose(:default_group_visibility) { |setting, _options| Gitlab::VisibilityLevel.string_level(setting.default_group_visibility) }

      expose(*::ApplicationSettingsHelper.external_authorization_service_attributes)

      # support legacy names, can be removed in v5
      expose :password_authentication_enabled_for_web, as: :password_authentication_enabled
      expose :password_authentication_enabled_for_web, as: :signin_enabled
      expose :allow_local_requests_from_web_hooks_and_services, as: :allow_local_requests_from_hooks_and_services
    end

    class Appearance < Grape::Entity
      expose :title
      expose :description

      expose :logo do |appearance, options|
        appearance.logo.url
      end

      expose :header_logo do |appearance, options|
        appearance.header_logo.url
      end

      expose :favicon do |appearance, options|
        appearance.favicon.url
      end

      expose :new_project_guidelines
      expose :header_message
      expose :footer_message
      expose :message_background_color
      expose :message_font_color
      expose :email_header_and_footer_enabled
    end

    # deprecated old Release representation
    class TagRelease < Grape::Entity
      expose :tag, as: :tag_name
      expose :description
    end

    module Releases
      class Link < Grape::Entity
        expose :id
        expose :name
        expose :url
        expose :external?, as: :external
      end

      class Source < Grape::Entity
        expose :format
        expose :url
      end
    end

    class Release < Grape::Entity
      include ::API::Helpers::Presentable

      expose :name do |release, _|
        can_download_code? ? release.name : "Release-#{release.id}"
      end
      expose :tag, as: :tag_name, if: ->(_, _) { can_download_code? }
      expose :description
      expose :description_html do |entity|
        MarkupHelper.markdown_field(entity, :description)
      end
      expose :created_at
      expose :released_at
      expose :author, using: Entities::UserBasic, if: -> (release, _) { release.author.present? }
      expose :commit, using: Entities::Commit, if: ->(_, _) { can_download_code? }
      expose :upcoming_release?, as: :upcoming_release
      expose :milestones, using: Entities::Milestone, if: -> (release, _) { release.milestones.present? && can_read_milestone? }
      expose :commit_path, expose_nil: false
      expose :tag_path, expose_nil: false
      expose :evidence_sha, expose_nil: false, if: ->(_, _) { can_download_code? }
      expose :assets do
        expose :assets_count, as: :count do |release, _|
          assets_to_exclude = can_download_code? ? [] : [:sources]
          release.assets_count(except: assets_to_exclude)
        end
        expose :sources, using: Entities::Releases::Source, if: ->(_, _) { can_download_code? }
        expose :links, using: Entities::Releases::Link do |release, options|
          release.links.sorted
        end
        expose :evidence_file_path, expose_nil: false, if: ->(_, _) { can_download_code? }
      end
      expose :_links do
        expose :merge_requests_url, expose_nil: false
        expose :issues_url, expose_nil: false
        expose :edit_url, expose_nil: false
      end

      private

      def can_download_code?
        Ability.allowed?(options[:current_user], :download_code, object.project)
      end

      def can_read_milestone?
        Ability.allowed?(options[:current_user], :read_milestone, object.project)
      end
    end

    class Tag < Grape::Entity
      expose :name, :message, :target

      expose :commit, using: Entities::Commit do |repo_tag, options|
        options[:project].repository.commit(repo_tag.dereferenced_target)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      expose :release, using: Entities::TagRelease do |repo_tag, options|
        options[:project].releases.find_by(tag: repo_tag.name)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      expose :protected do |repo_tag, options|
        ::ProtectedTag.protected?(options[:project], repo_tag.name)
      end
    end

    class Runner < Grape::Entity
      expose :id
      expose :description
      expose :ip_address
      expose :active
      expose :instance_type?, as: :is_shared
      expose :name
      expose :online?, as: :online
      expose :status
    end

    class RunnerDetails < Runner
      expose :tag_list
      expose :run_untagged
      expose :locked
      expose :maximum_timeout
      expose :access_level
      expose :version, :revision, :platform, :architecture
      expose :contacted_at
      expose :token, if: lambda { |runner, options| options[:current_user].admin? || !runner.instance_type? }
      # rubocop: disable CodeReuse/ActiveRecord
      expose :projects, with: Entities::BasicProjectDetails do |runner, options|
        if options[:current_user].admin?
          runner.projects
        else
          options[:current_user].authorized_projects.where(id: runner.projects)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
      # rubocop: disable CodeReuse/ActiveRecord
      expose :groups, with: Entities::BasicGroupDetails do |runner, options|
        if options[:current_user].admin?
          runner.groups
        else
          options[:current_user].authorized_groups.where(id: runner.groups)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end

    class RunnerRegistrationDetails < Grape::Entity
      expose :id, :token
    end

    class JobArtifactFile < Grape::Entity
      expose :filename
      expose :cached_size, as: :size
    end

    class JobArtifact < Grape::Entity
      expose :file_type, :size, :filename, :file_format
    end

    class JobBasic < Grape::Entity
      expose :id, :status, :stage, :name, :ref, :tag, :coverage, :allow_failure
      expose :created_at, :started_at, :finished_at
      expose :duration
      expose :user, with: User
      expose :commit, with: Commit
      expose :pipeline, with: PipelineBasic

      expose :web_url do |job, _options|
        Gitlab::Routing.url_helpers.project_job_url(job.project, job)
      end
    end

    class Job < JobBasic
      # artifacts_file is included in job_artifacts, but kept for backward compatibility (remove in api/v5)
      expose :artifacts_file, using: JobArtifactFile, if: -> (job, opts) { job.artifacts? }
      expose :job_artifacts, as: :artifacts, using: JobArtifact
      expose :runner, with: Runner
      expose :artifacts_expire_at
    end

    class JobBasicWithProject < JobBasic
      expose :project, with: ProjectIdentity
    end

    class Trigger < Grape::Entity
      include ::API::Helpers::Presentable

      expose :id
      expose :token
      expose :description
      expose :created_at, :updated_at, :last_used
      expose :owner, using: Entities::UserBasic
    end

    class Variable < Grape::Entity
      expose :variable_type, :key, :value
      expose :protected?, as: :protected, if: -> (entity, _) { entity.respond_to?(:protected?) }
      expose :masked?, as: :masked, if: -> (entity, _) { entity.respond_to?(:masked?) }
      expose :environment_scope, if: -> (entity, _) { entity.respond_to?(:environment_scope) }
    end

    class Pipeline < PipelineBasic
      expose :before_sha, :tag, :yaml_errors

      expose :user, with: Entities::UserBasic
      expose :created_at, :updated_at, :started_at, :finished_at, :committed_at
      expose :duration
      expose :coverage
      expose :detailed_status, using: DetailedStatusEntity do |pipeline, options|
        pipeline.detailed_status(options[:current_user])
      end
    end

    class PipelineSchedule < Grape::Entity
      expose :id
      expose :description, :ref, :cron, :cron_timezone, :next_run_at, :active
      expose :created_at, :updated_at
      expose :owner, using: Entities::UserBasic
    end

    class PipelineScheduleDetails < PipelineSchedule
      expose :last_pipeline, using: Entities::PipelineBasic
      expose :variables, using: Entities::Variable
    end

    class EnvironmentBasic < Grape::Entity
      expose :id, :name, :slug, :external_url
    end

    class Deployment < Grape::Entity
      expose :id, :iid, :ref, :sha, :created_at, :updated_at
      expose :user,        using: Entities::UserBasic
      expose :environment, using: Entities::EnvironmentBasic
      expose :deployable,  using: Entities::Job
      expose :status
    end

    class Environment < EnvironmentBasic
      expose :project, using: Entities::BasicProjectDetails
      expose :last_deployment, using: Entities::Deployment, if: { last_deployment: true }
      expose :state
    end

    class LicenseBasic < Grape::Entity
      expose :key, :name, :nickname
      expose :url, as: :html_url
      expose(:source_url) { |license| license.meta['source'] }
    end

    class License < LicenseBasic
      expose :popular?, as: :popular
      expose(:description) { |license| license.meta['description'] }
      expose(:conditions) { |license| license.meta['conditions'] }
      expose(:permissions) { |license| license.meta['permissions'] }
      expose(:limitations) { |license| license.meta['limitations'] }
      expose :content
    end

    class TemplatesList < Grape::Entity
      expose :key
      expose :name
    end

    class Template < Grape::Entity
      expose :name, :content
    end

    class BroadcastMessage < Grape::Entity
      expose :id, :message, :starts_at, :ends_at, :color, :font
      expose :active?, as: :active
    end

    class PersonalAccessToken < Grape::Entity
      expose :id, :name, :revoked, :created_at, :scopes
      expose :active?, as: :active
      expose :expires_at do |personal_access_token|
        personal_access_token.expires_at ? personal_access_token.expires_at.strftime("%Y-%m-%d") : nil
      end
    end

    class PersonalAccessTokenWithToken < PersonalAccessToken
      expose :token
    end

    class ImpersonationToken < PersonalAccessToken
      expose :impersonation
    end

    class ImpersonationTokenWithToken < PersonalAccessTokenWithToken
      expose :impersonation
    end

    class FeatureGate < Grape::Entity
      expose :key
      expose :value
    end

    class Feature < Grape::Entity
      expose :name
      expose :state
      expose :gates, using: FeatureGate do |model|
        model.gates.map do |gate|
          value = model.gate_values[gate.key]

          # By default all gate values are populated. Only show relevant ones.
          if (value.is_a?(Integer) && value.zero?) || (value.is_a?(Set) && value.empty?)
            next
          end

          { key: gate.key, value: value }
        end.compact
      end
    end

    module JobRequest
      class JobInfo < Grape::Entity
        expose :name, :stage
        expose :project_id, :project_name
      end

      class GitInfo < Grape::Entity
        expose :repo_url, :ref, :sha, :before_sha
        expose :ref_type
        expose :refspecs
        expose :git_depth, as: :depth
      end

      class RunnerInfo < Grape::Entity
        expose :metadata_timeout, as: :timeout
        expose :runner_session_url
      end

      class Step < Grape::Entity
        expose :name, :script, :timeout, :when, :allow_failure
      end

      class Port < Grape::Entity
        expose :number, :protocol, :name
      end

      class Image < Grape::Entity
        expose :name, :entrypoint
        expose :ports, using: JobRequest::Port
      end

      class Service < Image
        expose :alias, :command
      end

      class Artifacts < Grape::Entity
        expose :name
        expose :untracked
        expose :paths
        expose :when
        expose :expire_in
        expose :artifact_type
        expose :artifact_format
      end

      class Cache < Grape::Entity
        expose :key, :untracked, :paths, :policy
      end

      class Credentials < Grape::Entity
        expose :type, :url, :username, :password
      end

      class Dependency < Grape::Entity
        expose :id, :name, :token
        expose :artifacts_file, using: JobArtifactFile, if: ->(job, _) { job.artifacts? }
      end

      class Response < Grape::Entity
        expose :id
        expose :token
        expose :allow_git_fetch

        expose :job_info, using: JobInfo do |model|
          model
        end

        expose :git_info, using: GitInfo do |model|
          model
        end

        expose :runner_info, using: RunnerInfo do |model|
          model
        end

        expose :variables
        expose :steps, using: Step
        expose :image, using: Image
        expose :services, using: Service
        expose :artifacts, using: Artifacts
        expose :cache, using: Cache
        expose :credentials, using: Credentials
        expose :all_dependencies, as: :dependencies, using: Dependency
        expose :features
      end
    end

    class UserAgentDetail < Grape::Entity
      expose :user_agent
      expose :ip_address
      expose :submitted, as: :akismet_submitted
    end

    class CustomAttribute < Grape::Entity
      expose :key
      expose :value
    end

    class PagesDomainCertificateExpiration < Grape::Entity
      expose :expired?, as: :expired
      expose :expiration
    end

    class PagesDomainCertificate < Grape::Entity
      expose :subject
      expose :expired?, as: :expired
      expose :certificate
      expose :certificate_text
    end

    class PagesDomainBasic < Grape::Entity
      expose :domain
      expose :url
      expose :project_id
      expose :verified?, as: :verified
      expose :verification_code, as: :verification_code
      expose :enabled_until
      expose :auto_ssl_enabled

      expose :certificate,
        as: :certificate_expiration,
        if: ->(pages_domain, _) { pages_domain.certificate? },
        using: PagesDomainCertificateExpiration do |pages_domain|
        pages_domain
      end
    end

    class PagesDomain < Grape::Entity
      expose :domain
      expose :url
      expose :verified?, as: :verified
      expose :verification_code, as: :verification_code
      expose :enabled_until
      expose :auto_ssl_enabled

      expose :certificate,
        if: ->(pages_domain, _) { pages_domain.certificate? },
        using: PagesDomainCertificate do |pages_domain|
        pages_domain
      end
    end

    class Application < Grape::Entity
      expose :id
      expose :uid, as: :application_id
      expose :name, as: :application_name
      expose :redirect_uri, as: :callback_url
    end

    # Use with care, this exposes the secret
    class ApplicationWithSecret < Application
      expose :secret
    end

    class Blob < Grape::Entity
      expose :basename
      expose :data
      expose :path
      # TODO: :filename was renamed to :path but both still return the full path,
      # in the future we can only return the filename here without the leading
      # directory path.
      # https://gitlab.com/gitlab-org/gitlab/issues/34521
      expose :filename, &:path
      expose :id
      expose :ref
      expose :startline
      expose :project_id
    end

    class BasicBadgeDetails < Grape::Entity
      expose :name
      expose :link_url
      expose :image_url
      expose :rendered_link_url do |badge, options|
        badge.rendered_link_url(options.fetch(:project, nil))
      end
      expose :rendered_image_url do |badge, options|
        badge.rendered_image_url(options.fetch(:project, nil))
      end
    end

    class Badge < BasicBadgeDetails
      expose :id
      expose :kind do |badge|
        badge.type == 'ProjectBadge' ? 'project' : 'group'
      end
    end

    class ResourceLabelEvent < Grape::Entity
      expose :id
      expose :user, using: Entities::UserBasic
      expose :created_at
      expose :resource_type do |event, options|
        event.issuable.class.name
      end
      expose :resource_id do |event, options|
        event.issuable.id
      end
      expose :label, using: Entities::LabelBasic
      expose :action
    end

    class Suggestion < Grape::Entity
      expose :id
      expose :from_line
      expose :to_line
      expose :appliable?, as: :appliable
      expose :applied
      expose :from_content
      expose :to_content
    end

    module Platform
      class Kubernetes < Grape::Entity
        expose :api_url
        expose :namespace
        expose :authorization_type
        expose :ca_cert
      end
    end

    module Provider
      class Gcp < Grape::Entity
        expose :cluster_id
        expose :status_name
        expose :gcp_project_id
        expose :zone
        expose :machine_type
        expose :num_nodes
        expose :endpoint
      end
    end

    class Cluster < Grape::Entity
      expose :id, :name, :created_at, :domain
      expose :provider_type, :platform_type, :environment_scope, :cluster_type
      expose :user, using: Entities::UserBasic
      expose :platform_kubernetes, using: Entities::Platform::Kubernetes
      expose :provider_gcp, using: Entities::Provider::Gcp
      expose :management_project, using: Entities::ProjectIdentity
    end

    class ClusterProject < Cluster
      expose :project, using: Entities::BasicProjectDetails
    end

    class ClusterGroup < Cluster
      expose :group, using: Entities::BasicGroupDetails
    end

    module InternalPostReceive
      class Message < Grape::Entity
        expose :message
        expose :type
      end

      class Response < Grape::Entity
        expose :messages, using: Message
        expose :reference_counter_decreased
      end
    end
  end
end

# rubocop: disable Cop/InjectEnterpriseEditionModule
::API::Entities::ApplicationSetting.prepend_if_ee('EE::API::Entities::ApplicationSetting')
::API::Entities::Board.prepend_if_ee('EE::API::Entities::Board')
::API::Entities::Group.prepend_if_ee('EE::API::Entities::Group', with_descendants: true)
::API::Entities::GroupDetail.prepend_if_ee('EE::API::Entities::GroupDetail')
::API::Entities::IssueBasic.prepend_if_ee('EE::API::Entities::IssueBasic', with_descendants: true)
::API::Entities::Issue.prepend_if_ee('EE::API::Entities::Issue')
::API::Entities::List.prepend_if_ee('EE::API::Entities::List')
::API::Entities::MergeRequestBasic.prepend_if_ee('EE::API::Entities::MergeRequestBasic', with_descendants: true)
::API::Entities::Member.prepend_if_ee('EE::API::Entities::Member', with_descendants: true)
::API::Entities::Namespace.prepend_if_ee('EE::API::Entities::Namespace')
::API::Entities::Project.prepend_if_ee('EE::API::Entities::Project', with_descendants: true)
::API::Entities::ProtectedRefAccess.prepend_if_ee('EE::API::Entities::ProtectedRefAccess')
::API::Entities::UserPublic.prepend_if_ee('EE::API::Entities::UserPublic', with_descendants: true)
::API::Entities::Todo.prepend_if_ee('EE::API::Entities::Todo')
::API::Entities::ProtectedBranch.prepend_if_ee('EE::API::Entities::ProtectedBranch')
::API::Entities::Identity.prepend_if_ee('EE::API::Entities::Identity')
::API::Entities::UserWithAdmin.prepend_if_ee('EE::API::Entities::UserWithAdmin', with_descendants: true)
