# frozen_string_literal: true

module API
  module Entities
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

      expose(:can_create_merge_request_in) do |project, options|
        Ability.allowed?(options[:current_user], :create_merge_request_in, project)
      end

      expose(:issues_access_level) { |project, options| project.project_feature.string_access_level(:issues) }
      expose(:repository_access_level) { |project, options| project.project_feature.string_access_level(:repository) }
      expose(:merge_requests_access_level) { |project, options| project.project_feature.string_access_level(:merge_requests) }
      expose(:wiki_access_level) { |project, options| project.project_feature.string_access_level(:wiki) }
      expose(:builds_access_level) { |project, options| project.project_feature.string_access_level(:builds) }
      expose(:snippets_access_level) { |project, options| project.project_feature.string_access_level(:snippets) }
      expose(:pages_access_level) { |project, options| project.project_feature.string_access_level(:pages) }

      expose :emails_disabled
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
      expose :id, :title
      expose :slug do |service|
        service.to_param.dasherize
      end
      expose :created_at, :updated_at, :active
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
      expose :commit, using: Entities::Commit do |compare, _|
        compare.commits.last
      end

      expose :commits, using: Entities::Commit do |compare, _|
        compare.commits
      end

      expose :diffs, using: Entities::Diff do |compare, _|
        compare.diffs.diffs.to_a
      end

      expose :compare_timeout do |compare, _|
        compare.diffs.diffs.overflow?
      end

      expose :same, as: :compare_same_ref
    end

    class Contributor < Grape::Entity
      expose :name, :email, :commits, :additions, :deletions
    end

    class BroadcastMessage < Grape::Entity
      expose :message, :starts_at, :ends_at, :color, :font, :target_path, :broadcast_type
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
        expose :self_url, as: :self, expose_nil: false
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
      expose :confidential
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
