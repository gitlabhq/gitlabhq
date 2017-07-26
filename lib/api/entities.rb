module API
  module Entities
    class UserSafe < Grape::Entity
      expose :name, :username
    end

    class UserBasic < UserSafe
      expose :id, :state
      expose :avatar_url do |user, options|
        user.avatar_url(only_path: false)
      end

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
      expose :color_scheme_id, :projects_limit, :current_sign_in_at
      expose :identities, using: Entities::Identity
      expose :can_create_group?, as: :can_create_group
      expose :can_create_project?, as: :can_create_project
      expose :two_factor_enabled?, as: :two_factor_enabled
      expose :external

      # EE-only
      expose :shared_runners_minutes_limit
    end

    class UserWithAdmin < UserPublic
      expose :admin?, as: :is_admin
    end

    class UserWithPrivateDetails < UserWithAdmin
      expose :private_token
    end

    class Email < Grape::Entity
      expose :id, :email
    end

    class Hook < Grape::Entity
      expose :id, :url, :created_at, :push_events, :tag_push_events, :repository_update_events
      expose :enable_ssl_verification
    end

    class ProjectHook < Hook
      expose :project_id, :issues_events, :merge_requests_events
      expose :note_events, :pipeline_events, :wiki_page_events
      expose :job_events
    end

    class ProjectPushRule < Grape::Entity
      expose :id, :project_id, :created_at
      expose :commit_message_regex, :branch_name_regex, :deny_delete_tag
      expose :member_check, :prevent_secrets, :author_email_regex
      expose :file_name_regex, :max_file_size
    end

    class BasicProjectDetails < Grape::Entity
      expose :id
      expose :http_url_to_repo, :web_url
      expose :name, :name_with_namespace
      expose :path, :path_with_namespace
    end

    class SharedGroup < Grape::Entity
      expose :group_id
      expose :group_name do |group_link, options|
        group_link.group.name
      end
      expose :group_access, as: :group_access_level
    end

    class Project < Grape::Entity
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

      expose :id, :description, :default_branch, :tag_list
      expose :archived?, as: :archived
      expose :visibility, :ssh_url_to_repo, :http_url_to_repo, :web_url
      expose :owner, using: Entities::UserBasic, unless: ->(project, options) { project.group }
      expose :name, :name_with_namespace
      expose :path, :path_with_namespace
      expose :container_registry_enabled

      # Expose old field names with the new permissions methods to keep API compatible
      expose(:issues_enabled) { |project, options| project.feature_available?(:issues, options[:current_user]) }
      expose(:merge_requests_enabled) { |project, options| project.feature_available?(:merge_requests, options[:current_user]) }
      expose(:wiki_enabled) { |project, options| project.feature_available?(:wiki, options[:current_user]) }
      expose(:jobs_enabled) { |project, options| project.feature_available?(:builds, options[:current_user]) }
      expose(:snippets_enabled) { |project, options| project.feature_available?(:snippets, options[:current_user]) }

      expose :created_at, :last_activity_at
      expose :shared_runners_enabled
      expose :lfs_enabled?, as: :lfs_enabled
      expose :creator_id
      expose :namespace, using: 'API::Entities::Namespace'
      expose :forked_from_project, using: Entities::BasicProjectDetails, if: lambda{ |project, options| project.forked? }
      expose :import_status
      expose :import_error, if: lambda { |_project, options| options[:user_can_admin_project] }
      expose :avatar_url do |user, options|
        user.avatar_url(only_path: false)
      end
      expose :star_count, :forks_count
      expose :open_issues_count, if: lambda { |project, options| project.feature_available?(:issues, options[:current_user]) }
      expose :runners_token, if: lambda { |_project, options| options[:user_can_admin_project] }
      expose :public_builds, as: :public_jobs
      expose :ci_config_path
      expose :shared_with_groups do |project, options|
        SharedGroup.represent(project.project_group_links.all, options)
      end
      expose :only_allow_merge_if_pipeline_succeeds
      expose :repository_storage, if: lambda { |_project, options| options[:current_user].try(:admin?) }
      expose :request_access_enabled
      expose :only_allow_merge_if_all_discussions_are_resolved
      expose :printing_merge_request_link_enabled

      # EE only
      expose :approvals_before_merge, if: ->(project, _) { project.feature_available?(:merge_request_approvers) }

      expose :statistics, using: 'API::Entities::ProjectStatistics', if: :statistics
    end

    class ProjectStatistics < Grape::Entity
      expose :commit_count
      expose :storage_size
      expose :repository_size
      expose :lfs_objects_size
      expose :build_artifacts_size, as: :job_artifacts_size
    end

    class Member < UserBasic
      expose :access_level do |user, options|
        member = options[:member] || options[:source].members.find_by(user_id: user.id)
        member.access_level
      end
      expose :expires_at do |user, options|
        member = options[:member] || options[:source].members.find_by(user_id: user.id)
        member.expires_at
      end
    end

    class AccessRequester < UserBasic
      expose :requested_at do |user, options|
        access_requester = options[:access_requester] || options[:source].requesters.find_by(user_id: user.id)
        access_requester.requested_at
      end
    end

    class LdapGroupLink < Grape::Entity
      expose :cn, :group_access, :provider
    end

    class Group < Grape::Entity
      expose :id, :name, :path, :description, :visibility

      ## EE-only
      expose :ldap_cn, :ldap_access
      expose :ldap_group_links,
        using: Entities::LdapGroupLink,
        if: lambda { |group, options| group.ldap_group_links.any? }
      ## EE-only

      expose :lfs_enabled?, as: :lfs_enabled
      expose :avatar_url do |user, options|
        user.avatar_url(only_path: false)
      end
      expose :web_url
      expose :request_access_enabled
      expose :full_name, :full_path

      if ::Group.supports_nested_groups?
        expose :parent_id
      end

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
      expose :projects, using: Entities::Project
      expose :shared_projects, using: Entities::Project

      # EE-only
      expose :shared_runners_minutes_limit
    end

    class RepoCommit < Grape::Entity
      expose :id, :short_id, :title, :created_at
      expose :parent_ids
      expose :safe_message, as: :message
      expose :author_name, :author_email, :authored_date
      expose :committer_name, :committer_email, :committed_date
    end

    class RepoCommitStats < Grape::Entity
      expose :additions, :deletions, :total
    end

    class RepoCommitDetail < RepoCommit
      expose :stats, using: Entities::RepoCommitStats
      expose :status
    end

    class RepoBranch < Grape::Entity
      expose :name

      expose :commit, using: Entities::RepoCommit do |repo_branch, options|
        options[:project].repository.commit(repo_branch.dereferenced_target)
      end

      expose :merged do |repo_branch, options|
        options[:project].repository.merged_to_root_ref?(repo_branch.name)
      end

      expose :protected do |repo_branch, options|
        ProtectedBranch.protected?(options[:project], repo_branch.name)
      end

      expose :developers_can_push do |repo_branch, options|
        options[:project].protected_branches.developers_can?(:push, repo_branch.name)
      end

      expose :developers_can_merge do |repo_branch, options|
        options[:project].protected_branches.developers_can?(:merge, repo_branch.name)
      end
    end

    class RepoTreeObject < Grape::Entity
      expose :id, :name, :type, :path

      expose :mode do |obj, options|
        filemode = obj.mode
        filemode = "0" + filemode if filemode.length < 6
        filemode
      end
    end

    class ProjectSnippet < Grape::Entity
      expose :id, :title, :file_name, :description
      expose :author, using: Entities::UserBasic
      expose :updated_at, :created_at

      expose :web_url do |snippet, options|
        Gitlab::UrlBuilder.build(snippet)
      end
    end

    class PersonalSnippet < Grape::Entity
      expose :id, :title, :file_name, :description
      expose :author, using: Entities::UserBasic
      expose :updated_at, :created_at

      expose :web_url do |snippet|
        Gitlab::UrlBuilder.build(snippet)
      end
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

    class RepoDiff < Grape::Entity
      expose :old_path, :new_path, :a_mode, :b_mode, :diff
      expose :new_file?, as: :new_file
      expose :renamed_file?, as: :renamed_file
      expose :deleted_file?, as: :deleted_file
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
      expose :label_names, as: :labels
      expose :milestone, using: Entities::Milestone
      expose :assignees, :author, using: Entities::UserBasic

      expose :assignee, using: ::API::Entities::UserBasic do |issue, options|
        issue.assignees.first
      end

      expose :user_notes_count
      expose :upvotes, :downvotes
      expose :due_date
      expose :confidential
      expose :weight, if: ->(issue, _) { issue.supports_weight? }

      expose :web_url do |issue, options|
        Gitlab::UrlBuilder.build(issue)
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

    class RelatedIssue < Issue
      expose :issue_link_id
    end

    class IssueLink < Grape::Entity
      expose :source, as: :source_issue, using: Entities::IssueBasic
      expose :target, as: :target_issue, using: Entities::IssueBasic
    end

    class IssuableTimeStats < Grape::Entity
      expose :time_estimate
      expose :total_time_spent
      expose :human_time_estimate
      expose :human_total_time_spent
    end

    class ExternalIssue < Grape::Entity
      expose :title
      expose :id
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
      expose :merge_status
      expose :diff_head_sha, as: :sha
      expose :merge_commit_sha
      expose :user_notes_count
      expose :approvals_before_merge
      expose :should_remove_source_branch?, as: :should_remove_source_branch
      expose :force_remove_source_branch?, as: :force_remove_source_branch

      expose :squash, if: -> (mr, _) { mr.project.feature_available?(:merge_request_squash) }

      expose :web_url do |merge_request, options|
        Gitlab::UrlBuilder.build(merge_request)
      end
    end

    class MergeRequest < MergeRequestBasic
      expose :subscribed do |merge_request, options|
        merge_request.subscribed?(options[:current_user], options[:project])
      end
    end

    class MergeRequestChanges < MergeRequest
      expose :diffs, as: :changes, using: Entities::RepoDiff do |compare, _|
        compare.raw_diffs(limits: false).to_a
      end
    end

    class Approvals < Grape::Entity
      expose :user, using: Entities::UserBasic
    end

    class MergeRequestApprovals < ProjectEntity
      expose :merge_status
      expose :approvals_required
      expose :approvals_left
      expose :approvals, as: :approved_by, using: Entities::Approvals
      expose :approvers_left, as: :suggested_approvers, using: Entities::UserBasic

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
      expose :commits, using: Entities::RepoCommit

      expose :diffs, using: Entities::RepoDiff do |compare, _|
        compare.raw_diffs(limits: false).to_a
      end
    end

    class SSHKey < Grape::Entity
      expose :id, :title, :key, :created_at, :can_push
    end

    class SSHKeyWithUser < SSHKey
      expose :user, using: Entities::UserPublic
    end

    class Note < Grape::Entity
      expose :id
      expose :note, as: :body
      expose :attachment_identifier, as: :attachment
      expose :author, using: Entities::UserBasic
      expose :created_at, :updated_at
      expose :system?, as: :system
      expose :noteable_id, :noteable_type
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

    class Event < Grape::Entity
      expose :title, :project_id, :action_name
      expose :target_id, :target_type, :author_id
      expose :data, :target_title
      expose :created_at
      expose :note, using: Entities::Note, if: ->(event, options) { event.note? }
      expose :author, using: Entities::UserBasic, if: ->(event, options) { event.author }

      expose :author_username do |event, options|
        event.author&.username
      end
    end

    class LdapGroup < Grape::Entity
      expose :cn
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
        target = todo.target_type == 'Commit' ? 'RepoCommit' : todo.target_type
        Entities.const_get(target).represent(todo.target, options)
      end

      expose :target_url do |todo, options|
        target_type   = todo.target_type.underscore
        target_url    = "namespace_project_#{target_type}_url"
        target_anchor = "note_#{todo.note_id}" if todo.note_id?

        Gitlab::Routing.url_helpers.public_send(target_url,
          todo.project.namespace, todo.project, todo.target, anchor: target_anchor)
      end

      expose :body
      expose :state
      expose :created_at
    end

    class Namespace < Grape::Entity
      expose :id, :name, :path, :kind, :full_path, :parent_id

      expose :members_count_with_descendants, if: -> (namespace, opts) { expose_members_count_with_descendants?(namespace, opts) } do |namespace, _|
        namespace.users_with_descendants.count
      end

      def expose_members_count_with_descendants?(namespace, opts)
        namespace.kind == 'group' && Ability.allowed?(opts[:current_user], :admin_group, namespace)
      end

      # EE-only
      expose :shared_runners_minutes_limit, if: lambda { |_, options| options[:current_user]&.admin? }
      expose :plan, if: -> (namespace, opts) { Ability.allowed?(opts[:current_user], :admin_namespace, namespace) }
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
      expose :push_events, :issues_events, :merge_requests_events
      expose :tag_push_events, :note_events, :pipeline_events
      expose :job_events
      # Expose serialized properties
      expose :properties do |service, options|
        field_names = service.fields
          .select { |field| options[:include_passwords] || field[:type] != 'password' }
          .map { |field| field[:name] }
        service.properties.slice(*field_names)
      end
    end

    class ProjectWithAccess < Project
      expose :permissions do
        expose :project_access, using: Entities::ProjectAccess do |project, options|
          if options.key?(:project_members)
            (options[:project_members] || []).find { |member| member.source_id == project.id }
          else
            project.project_members.find_by(user_id: options[:current_user].id)
          end
        end

        expose :group_access, using: Entities::GroupAccess do |project, options|
          if project.group
            if options.key?(:group_members)
              (options[:group_members] || []).find { |member| member.source_id == project.namespace_id }
            else
              project.group.group_members.find_by(user_id: options[:current_user].id)
            end
          end
        end
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
      expose :name
      expose :project, using: Entities::BasicProjectDetails
      expose :milestone,
             if: -> (board, _) { board.project.feature_available?(:issue_board_milestone) }
      expose :lists, using: Entities::List do |board|
        board.lists.destroyable
      end
    end

    class Compare < Grape::Entity
      expose :commit, using: Entities::RepoCommit do |compare, options|
        Commit.decorate(compare.commits, nil).last
      end

      expose :commits, using: Entities::RepoCommit do |compare, options|
        Commit.decorate(compare.commits, nil)
      end

      expose :diffs, using: Entities::RepoDiff do |compare, options|
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
      expose :default_projects_limit
      expose :signup_enabled
      expose :password_authentication_enabled
      expose :password_authentication_enabled, as: :signin_enabled
      expose :gravatar_enabled
      expose :sign_in_text
      expose :after_sign_up_text
      expose :created_at
      expose :updated_at
      expose :home_page_url
      expose :default_branch_protection
      expose(:restricted_visibility_levels) do |setting, _options|
        setting.restricted_visibility_levels.map { |level| Gitlab::VisibilityLevel.string_level(level) }
      end
      expose :max_attachment_size
      expose :session_expire_delay
      expose(:default_project_visibility) { |setting, _options| Gitlab::VisibilityLevel.string_level(setting.default_project_visibility) }
      expose(:default_snippet_visibility) { |setting, _options| Gitlab::VisibilityLevel.string_level(setting.default_snippet_visibility) }
      expose(:default_group_visibility) { |setting, _options| Gitlab::VisibilityLevel.string_level(setting.default_group_visibility) }
      expose :default_artifacts_expire_in
      expose :domain_whitelist
      expose :domain_blacklist_enabled
      expose :domain_blacklist
      expose :user_oauth_applications
      expose :after_sign_out_path
      expose :container_registry_token_expire_delay
      expose :repository_storages
      expose :koding_enabled
      expose :koding_url
      expose :plantuml_enabled
      expose :plantuml_url
      expose :terminal_max_session_time
      expose :polling_interval_multiplier
      expose :help_page_hide_commercial_content
      expose :help_page_text
      expose :help_page_support_url
    end

    class Release < Grape::Entity
      expose :tag, as: :tag_name
      expose :description
    end

    class RepoTag < Grape::Entity
      expose :name, :message

      expose :commit do |repo_tag, options|
        options[:project].repository.commit(repo_tag.dereferenced_target)
      end

      expose :release, using: Entities::Release do |repo_tag, options|
        options[:project].releases.find_by(tag: repo_tag.name)
      end
    end

    class License < Grape::Entity
      expose :starts_at, :expires_at, :licensee, :add_ons

      expose :user_limit do |license, options|
        license.restricted?(:active_user_count) ? license.restrictions[:active_user_count] : 0
      end

      expose :active_users do |license, options|
        ::User.active.count
      end
    end

    class TriggerRequest < Grape::Entity
      expose :id, :variables
    end

    class Runner < Grape::Entity
      expose :id
      expose :description
      expose :active
      expose :is_shared
      expose :name
    end

    class RunnerDetails < Runner
      expose :tag_list
      expose :run_untagged
      expose :locked
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

    class PipelineBasic < Grape::Entity
      expose :id, :sha, :ref, :status
    end

    class Job < Grape::Entity
      expose :id, :status, :stage, :name, :ref, :tag, :coverage
      expose :created_at, :started_at, :finished_at
      expose :user, with: User
      expose :artifacts_file, using: JobArtifactFile, if: -> (job, opts) { job.artifacts? }
      expose :commit, with: RepoCommit
      expose :runner, with: Runner
      expose :pipeline, with: PipelineBasic
    end

    class Trigger < Grape::Entity
      expose :id
      expose :token, :description
      expose :created_at, :updated_at, :deleted_at, :last_used
      expose :owner, using: Entities::UserBasic
    end

    class Variable < Grape::Entity
      expose :key, :value
      expose :protected?, as: :protected

      # EE
      expose :environment_scope, if: ->(variable, options) {
        variable.project.feature_available?(:variable_environment_scope)
      }
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

    class RepoLicense < Grape::Entity
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

    class GeoNodeStatus < Grape::Entity
      expose :id
      expose :health
      expose :healthy?, as: :healthy
      expose :repositories_count
      expose :repositories_synced_count
      expose :repositories_failed_count
      expose :lfs_objects_count
      expose :lfs_objects_synced_count
      expose :attachments_count
      expose :attachments_synced_count
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
        expose :timeout
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

      class ArtifactFile < Grape::Entity
        expose :filename, :size
      end

      class Dependency < Grape::Entity
        expose :id, :name, :token
        expose :artifacts_file, using: ArtifactFile, if: ->(job, _) { job.artifacts? }
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
      end
    end

    class UserAgentDetail < Grape::Entity
      expose :user_agent
      expose :ip_address
      expose :submitted, as: :akismet_submitted
    end
  end
end
