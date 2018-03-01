module API
  module V3
    module Entities
      class ProjectSnippet < Grape::Entity
        expose :id, :title, :file_name
        expose :author, using: ::API::Entities::UserBasic
        expose :updated_at, :created_at
        expose(:expires_at) { |snippet| nil }

        expose :web_url do |snippet, options|
          Gitlab::UrlBuilder.build(snippet)
        end
      end

      class Note < Grape::Entity
        expose :id
        expose :note, as: :body
        expose :attachment_identifier, as: :attachment
        expose :author, using: ::API::Entities::UserBasic
        expose :created_at, :updated_at
        expose :system?, as: :system
        expose :noteable_id, :noteable_type
        # upvote? and downvote? are deprecated, always return false
        expose(:upvote?)    { |note| false }
        expose(:downvote?)  { |note| false }
      end

      class PushEventPayload < Grape::Entity
        expose :commit_count, :action, :ref_type, :commit_from, :commit_to
        expose :ref, :commit_title
      end

      class Event < Grape::Entity
        expose :project_id, :action_name
        expose :target_id, :target_type, :author_id
        expose :target_title
        expose :created_at
        expose :note, using: Entities::Note, if: ->(event, options) { event.note? }
        expose :author, using: ::API::Entities::UserBasic, if: ->(event, options) { event.author }

        expose :push_event_payload,
          as: :push_data,
          using: PushEventPayload,
          if: -> (event, _) { event.push? }

        expose :author_username do |event, options|
          event.author&.username
        end
      end

      class AwardEmoji < Grape::Entity
        expose :id
        expose :name
        expose :user, using: ::API::Entities::UserBasic
        expose :created_at, :updated_at
        expose :awardable_id, :awardable_type
      end

      class Project < Grape::Entity
        expose :id, :description, :default_branch, :tag_list
        expose :public?, as: :public
        expose :archived?, as: :archived
        expose :visibility_level, :ssh_url_to_repo, :http_url_to_repo, :web_url
        expose :owner, using: ::API::Entities::UserBasic, unless: ->(project, options) { project.group }
        expose :name, :name_with_namespace
        expose :path, :path_with_namespace
        expose :resolve_outdated_diff_discussions
        expose :container_registry_enabled

        # Expose old field names with the new permissions methods to keep API compatible
        expose(:issues_enabled) { |project, options| project.feature_available?(:issues, options[:current_user]) }
        expose(:merge_requests_enabled) { |project, options| project.feature_available?(:merge_requests, options[:current_user]) }
        expose(:wiki_enabled) { |project, options| project.feature_available?(:wiki, options[:current_user]) }
        expose(:builds_enabled) { |project, options| project.feature_available?(:builds, options[:current_user]) }
        expose(:snippets_enabled) { |project, options| project.feature_available?(:snippets, options[:current_user]) }

        expose :created_at, :last_activity_at
        expose :shared_runners_enabled
        expose :lfs_enabled?, as: :lfs_enabled
        expose :creator_id
        expose :namespace, using: 'API::Entities::Namespace'
        expose :forked_from_project, using: ::API::Entities::BasicProjectDetails, if: lambda { |project, options| project.forked? }
        expose :avatar_url do |user, options|
          user.avatar_url(only_path: false)
        end
        expose :star_count, :forks_count
        expose :open_issues_count, if: lambda { |project, options| project.feature_available?(:issues, options[:current_user]) && project.default_issues_tracker? }
        expose :runners_token, if: lambda { |_project, options| options[:user_can_admin_project] }
        expose :public_builds
        expose :shared_with_groups do |project, options|
          ::API::Entities::SharedGroup.represent(project.project_group_links.all, options)
        end
        expose :only_allow_merge_if_pipeline_succeeds, as: :only_allow_merge_if_build_succeeds
        expose :request_access_enabled
        expose :only_allow_merge_if_all_discussions_are_resolved

        expose :statistics, using: '::API::V3::Entities::ProjectStatistics', if: :statistics
      end

      class ProjectWithAccess < Project
        expose :permissions do
          expose :project_access, using: ::API::Entities::ProjectAccess do |project, options|
            project.project_members.find_by(user_id: options[:current_user].id)
          end

          expose :group_access, using: ::API::Entities::GroupAccess do |project, options|
            if project.group
              project.group.group_members.find_by(user_id: options[:current_user].id)
            end
          end
        end
      end

      class MergeRequest < Grape::Entity
        expose :id, :iid
        expose(:project_id) { |entity| entity.project.id }
        expose :title, :description
        expose :state, :created_at, :updated_at
        expose :target_branch, :source_branch
        expose :upvotes, :downvotes
        expose :author, :assignee, using: ::API::Entities::UserBasic
        expose :source_project_id, :target_project_id
        expose :label_names, as: :labels
        expose :work_in_progress?, as: :work_in_progress
        expose :milestone, using: ::API::Entities::Milestone
        expose :merge_when_pipeline_succeeds, as: :merge_when_build_succeeds
        expose :merge_status
        expose :diff_head_sha, as: :sha
        expose :merge_commit_sha
        expose :subscribed do |merge_request, options|
          merge_request.subscribed?(options[:current_user], options[:project])
        end
        expose :user_notes_count
        expose :should_remove_source_branch?, as: :should_remove_source_branch
        expose :force_remove_source_branch?, as: :force_remove_source_branch

        expose :web_url do |merge_request, options|
          Gitlab::UrlBuilder.build(merge_request)
        end
      end

      class Group < Grape::Entity
        expose :id, :name, :path, :description, :visibility_level
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
            expose :build_artifacts_size
          end
        end
      end

      class GroupDetail < Group
        expose :projects, using: Entities::Project
        expose :shared_projects, using: Entities::Project
      end

      class ApplicationSetting < Grape::Entity
        expose :id
        expose :default_projects_limit
        expose :signup_enabled
        expose :password_authentication_enabled_for_web, as: :password_authentication_enabled
        expose :password_authentication_enabled_for_web, as: :signin_enabled
        expose :gravatar_enabled
        expose :sign_in_text
        expose :after_sign_up_text
        expose :created_at
        expose :updated_at
        expose :home_page_url
        expose :default_branch_protection
        expose :restricted_visibility_levels
        expose :max_attachment_size
        expose :session_expire_delay
        expose :default_project_visibility
        expose :default_snippet_visibility
        expose :default_group_visibility
        expose :domain_whitelist
        expose :domain_blacklist_enabled
        expose :domain_blacklist
        expose :user_oauth_applications
        expose :after_sign_out_path
        expose :container_registry_token_expire_delay
        expose :repository_storage
        expose :repository_storages
        expose :koding_enabled
        expose :koding_url
        expose :plantuml_enabled
        expose :plantuml_url
        expose :terminal_max_session_time
      end

      class Environment < ::API::Entities::EnvironmentBasic
        expose :project, using: Entities::Project
      end

      class Trigger < Grape::Entity
        expose :token, :created_at, :updated_at, :last_used
        expose :owner, using: ::API::Entities::UserBasic
      end

      class TriggerRequest < Grape::Entity
        expose :id, :variables
      end

      class Build < Grape::Entity
        expose :id, :status, :stage, :name, :ref, :tag, :coverage
        expose :created_at, :started_at, :finished_at
        expose :user, with: ::API::Entities::User
        expose :artifacts_file, using: ::API::Entities::JobArtifactFile, if: -> (build, opts) { build.artifacts? }
        expose :commit, with: ::API::Entities::Commit
        expose :runner, with: ::API::Entities::Runner
        expose :pipeline, with: ::API::Entities::PipelineBasic
      end

      class BuildArtifactFile < Grape::Entity
        expose :filename, :size
      end

      class Deployment < Grape::Entity
        expose :id, :iid, :ref, :sha, :created_at
        expose :user,        using: ::API::Entities::UserBasic
        expose :environment, using: ::API::Entities::EnvironmentBasic
        expose :deployable,  using: Entities::Build
      end

      class MergeRequestChanges < MergeRequest
        expose :diffs, as: :changes, using: ::API::Entities::Diff do |compare, _|
          compare.raw_diffs(limits: false).to_a
        end
      end

      class ProjectStatistics < Grape::Entity
        expose :commit_count
        expose :storage_size
        expose :repository_size
        expose :lfs_objects_size
        expose :build_artifacts_size
      end

      class ProjectService < Grape::Entity
        expose :id, :title, :created_at, :updated_at, :active
        expose :push_events, :issues_events, :confidential_issues_events
        expose :merge_requests_events, :tag_push_events, :note_events
        expose :pipeline_events
        expose :job_events, as: :build_events
        # Expose serialized properties
        expose :properties do |service, options|
          service.properties.slice(*service.api_field_names)
        end
      end

      class ProjectHook < ::API::Entities::Hook
        expose :project_id, :issues_events, :confidential_issues_events
        expose :merge_requests_events, :note_events, :pipeline_events
        expose :wiki_page_events
        expose :job_events, as: :build_events
      end

      class ProjectEntity < Grape::Entity
        expose :id, :iid
        expose(:project_id) { |entity| entity&.project.try(:id) }
        expose :title, :description
        expose :state, :created_at, :updated_at
      end

      class IssueBasic < ProjectEntity
        expose :label_names, as: :labels
        expose :milestone, using: ::API::Entities::Milestone
        expose :assignees, :author, using: ::API::Entities::UserBasic

        expose :assignee, using: ::API::Entities::UserBasic do |issue, options|
          issue.assignees.first
        end

        expose :user_notes_count
        expose :upvotes, :downvotes
        expose :due_date
        expose :confidential

        expose :web_url do |issue, options|
          Gitlab::UrlBuilder.build(issue)
        end
      end

      class Issue < IssueBasic
        unexpose :assignees
        expose :assignee do |issue, options|
          ::API::Entities::UserBasic.represent(issue.assignees.first, options)
        end
        expose :subscribed do |issue, options|
          issue.subscribed?(options[:current_user], options[:project] || issue.project)
        end
      end
    end
  end
end
