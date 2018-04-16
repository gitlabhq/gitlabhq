module API
  module Entities
    class WikiPageBasic < Grape::Entity
      expose :format
      expose :slug
      expose :title
    end

    class WikiPage < WikiPageBasic
      expose :content
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
      expose :created_at
      expose :bio, :location, :skype, :linkedin, :twitter, :website_url, :organization
    end

    class UserActivity < Grape::Entity
      expose :username
      expose :last_activity_on
      expose :last_activity_on, as: :last_activity_at # Back-compat
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
    end

    class UserWithAdmin < UserPublic
      expose :admin?, as: :is_admin
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
    end

    class SharedGroup < Grape::Entity
      expose :group_id
      expose :group_name do |group_link, options|
        group_link.group.name
      end
      expose :group_access, as: :group_access_level
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

    class ProjectImportStatus < ProjectIdentity
      expose :import_status

      # TODO: Use `expose_nil` once we upgrade the grape-entity gem
      expose :import_error, if: lambda { |status, _ops| status.import_error }
    end

    class BasicProjectDetails < ProjectIdentity
      include ::API::ProjectsRelationBuilder

      expose :default_branch
      # Avoids an N+1 query: https://github.com/mbleigh/acts-as-taggable-on/issues/91#issuecomment-168273770
      expose :tag_list do |project|
        # project.tags.order(:name).pluck(:name) is the most suitable option
        # to avoid loading all the ActiveRecord objects but, if we use it here
        # it override the preloaded associations and makes a query
        # (fixed in https://github.com/rails/rails/pull/25976).
        project.tags.map(&:name).sort
      end
      expose :ssh_url_to_repo, :http_url_to_repo, :web_url
      expose :avatar_url do |project, options|
        project.avatar_url(only_path: false)
      end
      expose :star_count, :forks_count
      expose :last_activity_at

      expose :custom_attributes, using: 'API::Entities::CustomAttribute', if: :with_custom_attributes

      def self.preload_relation(projects_relation, options =  {})
        projects_relation.preload(:project_feature, :route)
                         .preload(namespace: [:route, :owner],
                                  tags: :taggings)
      end
    end

    class Project < BasicProjectDetails
      include ::API::Helpers::RelatedResourcesHelpers

      expose :_links do
        expose :self do |project|
          expose_url(api_v4_projects_path(id: project.id))
        end

        expose :issues, if: -> (*args) { issues_available?(*args) } do |project|
          expose_url(api_v4_projects_issues_path(id: project.id))
        end

        expose :merge_requests, if: -> (*args) { mrs_available?(*args) } do |project|
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

      expose :archived?, as: :archived
      expose :visibility
      expose :owner, using: Entities::UserBasic, unless: ->(project, options) { project.group }
      expose :resolve_outdated_diff_discussions
      expose :container_registry_enabled

      # Expose old field names with the new permissions methods to keep API compatible
      expose(:issues_enabled) { |project, options| project.feature_available?(:issues, options[:current_user]) }
      expose(:merge_requests_enabled) { |project, options| project.feature_available?(:merge_requests, options[:current_user]) }
      expose(:wiki_enabled) { |project, options| project.feature_available?(:wiki, options[:current_user]) }
      expose(:jobs_enabled) { |project, options| project.feature_available?(:builds, options[:current_user]) }
      expose(:snippets_enabled) { |project, options| project.feature_available?(:snippets, options[:current_user]) }

      expose :shared_runners_enabled
      expose :lfs_enabled?, as: :lfs_enabled
      expose :creator_id
      expose :namespace, using: 'API::Entities::NamespaceBasic'
      expose :forked_from_project, using: Entities::BasicProjectDetails, if: lambda { |project, options| project.forked? }
      expose :import_status
      expose :import_error, if: lambda { |_project, options| options[:user_can_admin_project] }

      expose :open_issues_count, if: lambda { |project, options| project.feature_available?(:issues, options[:current_user]) }
      expose :runners_token, if: lambda { |_project, options| options[:user_can_admin_project] }
      expose :public_builds, as: :public_jobs
      expose :ci_config_path
      expose :shared_with_groups do |project, options|
        SharedGroup.represent(project.project_group_links, options)
      end
      expose :only_allow_merge_if_pipeline_succeeds
      expose :request_access_enabled
      expose :only_allow_merge_if_all_discussions_are_resolved
      expose :printing_merge_request_link_enabled
      expose :merge_method

      expose :statistics, using: 'API::Entities::ProjectStatistics', if: :statistics

      def self.preload_relation(projects_relation, options =  {})
        super(projects_relation).preload(:group)
                                .preload(project_group_links: :group,
                                         fork_network: :root_project,
                                         forked_project_link: :forked_from_project,
                                         forked_from_project: [:route, :forks, namespace: :route, tags: :taggings])
      end

      def self.forks_counting_projects(projects_relation)
        projects_relation + projects_relation.map(&:forked_from_project).compact
      end
    end

    class ProjectStatistics < Grape::Entity
      expose :commit_count
      expose :storage_size
      expose :repository_size
      expose :lfs_objects_size
      expose :build_artifacts_size, as: :job_artifacts_size
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

    class Group < Grape::Entity
      expose :id, :name, :path, :description, :visibility

      expose :lfs_enabled?, as: :lfs_enabled
      expose :avatar_url do |group, options|
        group.avatar_url(only_path: false)
      end
      expose :web_url
      expose :request_access_enabled
      expose :full_name, :full_path

      if ::Group.supports_nested_groups?
        expose :parent_id
      end

      expose :custom_attributes, using: 'API::Entities::CustomAttribute', if: :with_custom_attributes

      expose :statistics, if: :statistics do
        with_options format_with: -> (value) { value.to_i } do
          expose :storage_size
          expose :repository_size
          expose :lfs_objects_size
          expose :build_artifacts_size, as: :job_artifacts_size
        end
      end
    end

    class GroupDetail < Group
      expose :projects, using: Entities::Project do |group, options|
        GroupProjectsFinder.new(
          group: group,
          current_user: options[:current_user],
          options: { only_owned: true }
        ).execute
      end

      expose :shared_projects, using: Entities::Project do |group, options|
        GroupProjectsFinder.new(
          group: group,
          current_user: options[:current_user],
          options: { only_shared: true }
        ).execute
      end
    end

    class Commit < Grape::Entity
      expose :id, :short_id, :title, :created_at
      expose :parent_ids
      expose :safe_message, as: :message
      expose :author_name, :author_email, :authored_date
      expose :committer_name, :committer_email, :committed_date
    end

    class CommitStats < Grape::Entity
      expose :additions, :deletions, :total
    end

    class CommitDetail < Commit
      expose :stats, using: Entities::CommitStats, if: :stats
      expose :status
      expose :last_pipeline, using: 'API::Entities::PipelineBasic'
      expose :project_id
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
        options[:project].protected_branches.developers_can?(:push, repo_branch.name)
      end

      expose :developers_can_merge do |repo_branch, options|
        options[:project].protected_branches.developers_can?(:merge, repo_branch.name)
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
      expose :id, :title, :file_name, :description
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
        Gitlab::UrlBuilder.build(snippet) + "/raw"
      end
    end

    class ProjectEntity < Grape::Entity
      expose :id, :iid
      expose(:project_id) { |entity| entity&.project.try(:id) }
      expose :title, :description
      expose :state, :created_at, :updated_at
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
      expose :unprotect_access_levels, using: Entities::ProtectedRefAccess
    end

    class Milestone < Grape::Entity
      expose :id, :iid
      expose :project_id, if: -> (entity, options) { entity&.project_id }
      expose :group_id, if: -> (entity, options) { entity&.group_id }
      expose :title, :description
      expose :state, :created_at, :updated_at
      expose :due_date
      expose :start_date
    end

    class IssueBasic < ProjectEntity
      expose :closed_at
      expose :closed_by, using: Entities::UserBasic
      expose :labels do |issue, options|
        # Avoids an N+1 query since labels are preloaded
        issue.labels.map(&:title).sort
      end
      expose :milestone, using: Entities::Milestone
      expose :assignees, :author, using: Entities::UserBasic

      expose :assignee, using: ::API::Entities::UserBasic do |issue, options|
        issue.assignees.first
      end

      expose :user_notes_count
      expose :upvotes do |issue, options|
        if options[:issuable_metadata]
          # Avoids an N+1 query when metadata is included
          options[:issuable_metadata][issue.id].upvotes
        else
          issue.upvotes
        end
      end
      expose :downvotes do |issue, options|
        if options[:issuable_metadata]
          # Avoids an N+1 query when metadata is included
          options[:issuable_metadata][issue.id].downvotes
        else
          issue.downvotes
        end
      end
      expose :due_date
      expose :confidential
      expose :discussion_locked

      expose :web_url do |issue, options|
        Gitlab::UrlBuilder.build(issue)
      end

      expose :time_stats, using: 'API::Entities::IssuableTimeStats' do |issue|
        issue
      end
    end

    class Issue < IssueBasic
      include ::API::Helpers::RelatedResourcesHelpers

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

      expose :subscribed do |issue, options|
        issue.subscribed?(options[:current_user], options[:project] || issue.project)
      end
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

      def total_time_spent
        # Avoids an N+1 query since timelogs are preloaded
        object.timelogs.map(&:time_spent).sum
      end
    end

    class ExternalIssue < Grape::Entity
      expose :title
      expose :id
    end

    class PipelineBasic < Grape::Entity
      expose :id, :sha, :ref, :status
    end

    class MergeRequestSimple < ProjectEntity
      expose :title
      expose :web_url do |merge_request, options|
        Gitlab::UrlBuilder.build(merge_request)
      end
    end

    class MergeRequestBasic < ProjectEntity
      expose :target_branch, :source_branch
      expose :upvotes do |merge_request, options|
        if options[:issuable_metadata]
          options[:issuable_metadata][merge_request.id].upvotes
        else
          merge_request.upvotes
        end
      end
      expose :downvotes do |merge_request, options|
        if options[:issuable_metadata]
          options[:issuable_metadata][merge_request.id].downvotes
        else
          merge_request.downvotes
        end
      end
      expose :author, :assignee, using: Entities::UserBasic
      expose :source_project_id, :target_project_id
      expose :labels do |merge_request, options|
        # Avoids an N+1 query since labels are preloaded
        merge_request.labels.map(&:title).sort
      end
      expose :work_in_progress?, as: :work_in_progress
      expose :milestone, using: Entities::Milestone
      expose :merge_when_pipeline_succeeds

      # Ideally we should deprecate `MergeRequest#merge_status` exposure and
      # use `MergeRequest#mergeable?` instead (boolean).
      # See https://gitlab.com/gitlab-org/gitlab-ce/issues/42344 for more
      # information.
      expose :merge_status do |merge_request|
        merge_request.check_if_can_be_merged
        merge_request.merge_status
      end
      expose :diff_head_sha, as: :sha
      expose :merge_commit_sha
      expose :user_notes_count
      expose :discussion_locked
      expose :should_remove_source_branch?, as: :should_remove_source_branch
      expose :force_remove_source_branch?, as: :force_remove_source_branch
      expose :allow_maintainer_to_push, if: -> (merge_request, _) { merge_request.for_fork? }

      expose :web_url do |merge_request, options|
        Gitlab::UrlBuilder.build(merge_request)
      end

      expose :time_stats, using: 'API::Entities::IssuableTimeStats' do |merge_request|
        merge_request
      end
    end

    class MergeRequest < MergeRequestBasic
      expose :subscribed do |merge_request, options|
        merge_request.subscribed?(options[:current_user], options[:project])
      end

      expose :changes_count do |merge_request, _options|
        merge_request.merge_request_diff.real_size
      end

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

      def build_available?(options)
        options[:project]&.feature_available?(:builds, options[:current_user])
      end
    end

    class MergeRequestChanges < MergeRequest
      expose :diffs, as: :changes, using: Entities::Diff do |compare, _|
        compare.raw_diffs(limits: false).to_a
      end
    end

    class Approver < Grape::Entity
      expose :user, using: Entities::UserBasic
    end

    class ApproverGroup < Grape::Entity
      expose :group, using: Entities::Group
    end

    class MergeRequestApprovals < ProjectEntity
      expose :merge_status
      expose :approvals_required
      expose :approvals_left
      expose :approvals, as: :approved_by, using: Entities::Approver
      expose :approvers_left, as: :suggested_approvers, using: Entities::UserBasic
      expose :approvers, using: Entities::Approver
      expose :approver_groups, using: Entities::ApproverGroup

      expose :user_has_approved do |merge_request, options|
        merge_request.has_approved?(options[:current_user])
      end

      expose :user_can_approve do |merge_request, options|
        merge_request.can_approve?(options[:current_user])
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

    class DeployKeysProject < Grape::Entity
      expose :deploy_key, merge: true, using: Entities::SSHKey
      expose :can_push
    end

    class GPGKey < Grape::Entity
      expose :id, :key, :created_at
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

      # Avoid N+1 queries as much as possible
      expose(:noteable_iid) { |note| note.noteable.iid if NOTEABLE_TYPES_WITH_IID.include?(note.noteable_type) }
    end

    class Discussion < Grape::Entity
      expose :id
      expose :individual_note?, as: :individual_note
      expose :notes, using: Entities::Note
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
      expose :commit_count, :action, :ref_type, :commit_from, :commit_to
      expose :ref, :commit_title
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
        if: -> (event, _) { event.push? }

      expose :author_username do |event, options|
        event.author&.username
      end
    end

    class ProjectGroupLink < Grape::Entity
      expose :id, :project_id, :group_id, :group_access, :expires_at
    end

    class Todo < Grape::Entity
      expose :id
      expose :project, using: Entities::BasicProjectDetails
      expose :author, using: Entities::UserBasic
      expose :action_name
      expose :target_type

      expose :target do |todo, options|
        Entities.const_get(todo.target_type).represent(todo.target, options)
      end

      expose :target_url do |todo, options|
        target_type   = todo.target_type.underscore
        target_url    = "namespace_project_#{target_type}_url"
        target_anchor = "note_#{todo.note_id}" if todo.note_id?

        Gitlab::Routing
          .url_helpers
          .public_send(target_url, todo.project.namespace, todo.project, todo.target, anchor: target_anchor) # rubocop:disable GitlabSecurity/PublicSend
      end

      expose :body
      expose :state
      expose :created_at
    end

    class NamespaceBasic < Grape::Entity
      expose :id, :name, :path, :kind, :full_path, :parent_id
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
        ::NotificationSetting::EMAIL_EVENTS.each do |event|
          expose event
        end
      end
    end

    class GlobalNotificationSetting < NotificationSetting
      expose :notification_email do |notification_setting, options|
        notification_setting.user.notification_email
      end
    end

    class ProjectService < Grape::Entity
      expose :id, :title, :created_at, :updated_at, :active
      expose :push_events, :issues_events, :confidential_issues_events
      expose :merge_requests_events, :tag_push_events, :note_events
      expose :confidential_note_events, :pipeline_events, :wiki_page_events
      expose :job_events
      # Expose serialized properties
      expose :properties do |service, options|
        service.properties.slice(*service.api_field_names)
      end
    end

    class ProjectWithAccess < Project
      expose :permissions do
        expose :project_access, using: Entities::ProjectAccess do |project, options|
          if options.key?(:project_members)
            (options[:project_members] || []).find { |member| member.source_id == project.id }
          else
            project.project_member(options[:current_user])
          end
        end

        expose :group_access, using: Entities::GroupAccess do |project, options|
          if project.group
            if options.key?(:group_members)
              (options[:group_members] || []).find { |member| member.source_id == project.namespace_id }
            else
              project.group.group_member(options[:current_user])
            end
          end
        end
      end

      def self.preload_relation(projects_relation, options = {})
        relation = super(projects_relation, options)

        unless options.key?(:group_members)
          relation = relation.preload(group: [group_members: [:source, user: [notification_settings: :source]]])
        end

        unless options.key?(:project_members)
          relation = relation.preload(project_members: [:source, user: [notification_settings: :source]])
        end

        relation
      end
    end

    class LabelBasic < Grape::Entity
      expose :id, :name, :color, :description
    end

    class Label < LabelBasic
      expose :open_issues_count do |label, options|
        label.open_issues_count(options[:current_user])
      end

      expose :closed_issues_count do |label, options|
        label.closed_issues_count(options[:current_user])
      end

      expose :open_merge_requests_count do |label, options|
        label.open_merge_requests_count(options[:current_user])
      end

      expose :priority do |label, options|
        label.priority(options[:project])
      end

      expose :subscribed do |label, options|
        label.subscribed?(options[:current_user], options[:project])
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
        board.lists.destroyable
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
      expose :message, :starts_at, :ends_at, :color, :font
    end

    class ApplicationSetting < Grape::Entity
      expose :id
      expose(*::ApplicationSettingsHelper.visible_attributes)
      expose(:restricted_visibility_levels) do |setting, _options|
        setting.restricted_visibility_levels.map { |level| Gitlab::VisibilityLevel.string_level(level) }
      end
      expose(:default_project_visibility) { |setting, _options| Gitlab::VisibilityLevel.string_level(setting.default_project_visibility) }
      expose(:default_snippet_visibility) { |setting, _options| Gitlab::VisibilityLevel.string_level(setting.default_snippet_visibility) }
      expose(:default_group_visibility) { |setting, _options| Gitlab::VisibilityLevel.string_level(setting.default_group_visibility) }

      # support legacy names, can be removed in v5
      expose :password_authentication_enabled_for_web, as: :password_authentication_enabled
      expose :password_authentication_enabled_for_web, as: :signin_enabled
    end

    class Release < Grape::Entity
      expose :tag, as: :tag_name
      expose :description
    end

    class Tag < Grape::Entity
      expose :name, :message, :target

      expose :commit, using: Entities::Commit do |repo_tag, options|
        options[:project].repository.commit(repo_tag.dereferenced_target)
      end

      expose :release, using: Entities::Release do |repo_tag, options|
        options[:project].releases.find_by(tag: repo_tag.name)
      end
    end

    class Runner < Grape::Entity
      expose :id
      expose :description
      expose :active
      expose :is_shared
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
      expose :token, if: lambda { |runner, options| options[:current_user].admin? || !runner.is_shared? }
      expose :projects, with: Entities::BasicProjectDetails do |runner, options|
        if options[:current_user].admin?
          runner.projects
        else
          options[:current_user].authorized_projects.where(id: runner.projects)
        end
      end
    end

    class RunnerRegistrationDetails < Grape::Entity
      expose :id, :token
    end

    class JobArtifactFile < Grape::Entity
      expose :filename, :size
    end

    class JobBasic < Grape::Entity
      expose :id, :status, :stage, :name, :ref, :tag, :coverage
      expose :created_at, :started_at, :finished_at
      expose :duration
      expose :user, with: User
      expose :commit, with: Commit
      expose :pipeline, with: PipelineBasic
    end

    class Job < JobBasic
      expose :artifacts_file, using: JobArtifactFile, if: -> (job, opts) { job.artifacts? }
      expose :runner, with: Runner
    end

    class JobBasicWithProject < JobBasic
      expose :project, with: ProjectIdentity
    end

    class Trigger < Grape::Entity
      expose :id
      expose :token, :description
      expose :created_at, :updated_at, :last_used
      expose :owner, using: Entities::UserBasic
    end

    class Variable < Grape::Entity
      expose :key, :value
      expose :protected?, as: :protected, if: -> (entity, _) { entity.respond_to?(:protected?) }
    end

    class Pipeline < PipelineBasic
      expose :before_sha, :tag, :yaml_errors

      expose :user, with: Entities::UserBasic
      expose :created_at, :updated_at, :started_at, :finished_at, :committed_at
      expose :duration
      expose :coverage
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

    class Environment < EnvironmentBasic
      expose :project, using: Entities::BasicProjectDetails
    end

    class Deployment < Grape::Entity
      expose :id, :iid, :ref, :sha, :created_at
      expose :user,        using: Entities::UserBasic
      expose :environment, using: Entities::EnvironmentBasic
      expose :deployable,  using: Entities::Job
    end

    class License < Grape::Entity
      expose :key, :name, :nickname
      expose :featured, as: :popular
      expose :url, as: :html_url
      expose(:source_url) { |license| license.meta['source'] }
      expose(:description) { |license| license.meta['description'] }
      expose(:conditions) { |license| license.meta['conditions'] }
      expose(:permissions) { |license| license.meta['permissions'] }
      expose(:limitations) { |license| license.meta['limitations'] }
      expose :content
    end

    class TemplatesList < Grape::Entity
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

    class ImpersonationToken < PersonalAccessTokenWithToken
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
        expose :ref_type do |model|
          if model.tag
            'tag'
          else
            'branch'
          end
        end
      end

      class RunnerInfo < Grape::Entity
        expose :metadata_timeout, as: :timeout
      end

      class Step < Grape::Entity
        expose :name, :script, :timeout, :when, :allow_failure
      end

      class Image < Grape::Entity
        expose :name, :entrypoint
      end

      class Service < Image
        expose :alias, :command
      end

      class Artifacts < Grape::Entity
        expose :name, :untracked, :paths, :when, :expire_in
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
        expose :dependencies, using: Dependency
        expose :features
      end
    end

    class UserAgentDetail < Grape::Entity
      expose :user_agent
      expose :ip_address
      expose :submitted, as: :akismet_submitted
    end

    class RepositoryStorageHealth < Grape::Entity
      expose :storage_name
      expose :failing_on_hosts
      expose :total_failures
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

      expose :certificate,
        if: ->(pages_domain, _) { pages_domain.certificate? },
        using: PagesDomainCertificate do |pages_domain|
        pages_domain
      end
    end

    class Application < Grape::Entity
      expose :uid, as: :application_id
      expose :redirect_uri, as: :callback_url
    end

    # Use with care, this exposes the secret
    class ApplicationWithSecret < Application
      expose :secret
    end

    class Blob < Grape::Entity
      expose :basename
      expose :data
      expose :filename
      expose :id
      expose :ref
      expose :startline
      expose :project_id
    end

    class BasicBadgeDetails < Grape::Entity
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

    def self.prepend_entity(klass, with: nil)
      if with.nil?
        raise ArgumentError, 'You need to pass either the :with or :namespace option!'
      end

      klass.descendants.each { |descendant| descendant.prepend(with) }
      klass.prepend(with)
    end

    class ApprovalSettings < Grape::Entity
      expose :approvers, using: Entities::Approver
      expose :approver_groups, using: Entities::ApproverGroup
      expose :approvals_before_merge
      expose :reset_approvals_on_push
      expose :disable_overriding_approvers_per_merge_request
    end
  end
end

API::Entities.prepend_entity(::API::Entities::ApplicationSetting, with: EE::API::Entities::ApplicationSetting)
API::Entities.prepend_entity(::API::Entities::Board, with: EE::API::Entities::Board)
API::Entities.prepend_entity(::API::Entities::Group, with: EE::API::Entities::Group)
API::Entities.prepend_entity(::API::Entities::GroupDetail, with: EE::API::Entities::GroupDetail)
API::Entities.prepend_entity(::API::Entities::IssueBasic, with: EE::API::Entities::IssueBasic)
API::Entities.prepend_entity(::API::Entities::MergeRequestBasic, with: EE::API::Entities::MergeRequestBasic)
API::Entities.prepend_entity(::API::Entities::Namespace, with: EE::API::Entities::Namespace)
API::Entities.prepend_entity(::API::Entities::Project, with: EE::API::Entities::Project)
API::Entities.prepend_entity(::API::Entities::ProtectedRefAccess, with: EE::API::Entities::ProtectedRefAccess)
API::Entities.prepend_entity(::API::Entities::UserPublic, with: EE::API::Entities::UserPublic)
API::Entities.prepend_entity(::API::Entities::Variable, with: EE::API::Entities::Variable)
