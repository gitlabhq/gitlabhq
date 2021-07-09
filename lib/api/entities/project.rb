# frozen_string_literal: true

module API
  module Entities
    class Project < BasicProjectDetails
      include ::API::Helpers::RelatedResourcesHelpers

      expose :container_registry_url, as: :container_registry_image_prefix, if: -> (_, _) { Gitlab.config.registry.enabled }

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

      expose :packages_enabled
      expose :empty_repo?, as: :empty_repo
      expose :archived?, as: :archived
      expose :visibility
      expose :owner, using: Entities::UserBasic, unless: ->(project, options) { project.group }
      expose :resolve_outdated_diff_discussions
      expose :container_expiration_policy, using: Entities::ContainerExpirationPolicy,
        if: -> (project, _) { project.container_expiration_policy }

      # Expose old field names with the new permissions methods to keep API compatible
      # TODO: remove in API v5, replaced by *_access_level
      expose(:issues_enabled) { |project, options| project.feature_available?(:issues, options[:current_user]) }
      expose(:merge_requests_enabled) { |project, options| project.feature_available?(:merge_requests, options[:current_user]) }
      expose(:wiki_enabled) { |project, options| project.feature_available?(:wiki, options[:current_user]) }
      expose(:jobs_enabled) { |project, options| project.feature_available?(:builds, options[:current_user]) }
      expose(:snippets_enabled) { |project, options| project.feature_available?(:snippets, options[:current_user]) }
      expose(:container_registry_enabled) { |project, options| project.feature_available?(:container_registry, options[:current_user]) }
      expose :service_desk_enabled
      expose :service_desk_address

      expose(:can_create_merge_request_in) do |project, options|
        Ability.allowed?(options[:current_user], :create_merge_request_in, project)
      end

      expose(:issues_access_level) { |project, options| project.project_feature.string_access_level(:issues) }
      expose(:repository_access_level) { |project, options| project.project_feature.string_access_level(:repository) }
      expose(:merge_requests_access_level) { |project, options| project.project_feature.string_access_level(:merge_requests) }
      expose(:forking_access_level) { |project, options| project.project_feature.string_access_level(:forking) }
      expose(:wiki_access_level) { |project, options| project.project_feature.string_access_level(:wiki) }
      expose(:builds_access_level) { |project, options| project.project_feature.string_access_level(:builds) }
      expose(:snippets_access_level) { |project, options| project.project_feature.string_access_level(:snippets) }
      expose(:pages_access_level) { |project, options| project.project_feature.string_access_level(:pages) }
      expose(:operations_access_level) { |project, options| project.project_feature.string_access_level(:operations) }
      expose(:analytics_access_level) { |project, options| project.project_feature.string_access_level(:analytics) }

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
      expose :ci_forward_deployment_enabled
      expose :ci_job_token_scope_enabled
      expose :public_builds, as: :public_jobs
      expose :build_git_strategy, if: lambda { |project, options| options[:user_can_admin_project] } do |project, options|
        project.build_allow_git_fetch ? 'fetch' : 'clone'
      end
      expose :build_timeout
      expose :auto_cancel_pending_pipelines
      expose :build_coverage_regex
      expose :ci_config_path, if: -> (project, options) { Ability.allowed?(options[:current_user], :download_code, project) }
      expose :shared_with_groups do |project, options|
        SharedGroupWithProject.represent(project.project_group_links, options)
      end
      expose :only_allow_merge_if_pipeline_succeeds
      expose :allow_merge_on_skipped_pipeline
      expose :restrict_user_defined_variables
      expose :request_access_enabled
      expose :only_allow_merge_if_all_discussions_are_resolved
      expose :remove_source_branch_after_merge
      expose :printing_merge_request_link_enabled
      expose :merge_method
      expose :squash_option
      expose :suggestion_commit_message
      expose :statistics, using: 'API::Entities::ProjectStatistics', if: -> (project, options) {
        options[:statistics] && Ability.allowed?(options[:current_user], :read_statistics, project)
      }
      expose :auto_devops_enabled?, as: :auto_devops_enabled
      expose :auto_devops_deploy_strategy do |project, options|
        project.auto_devops.nil? ? 'continuous' : project.auto_devops.deploy_strategy
      end
      expose :autoclose_referenced_issues
      expose :repository_storage, if: ->(project, options) {
        Ability.allowed?(options[:current_user], :change_repository_storage, project)
      }
      expose :keep_latest_artifacts_available?, as: :keep_latest_artifact

      # rubocop: disable CodeReuse/ActiveRecord
      def self.preload_relation(projects_relation, options = {})
        # Preloading topics, should be done with using only `:topics`,
        # as `:topics` are defined as: `has_many :topics, through: :taggings`
        # N+1 is solved then by using `subject.topics.map(&:name)`
        # MR describing the solution: https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/20555
        super(projects_relation).preload(group: :namespace_settings)
                                .preload(:ci_cd_settings)
                                .preload(:project_setting)
                                .preload(:container_expiration_policy)
                                .preload(:auto_devops)
                                .preload(:service_desk_setting)
                                .preload(project_group_links: { group: :route },
                                         fork_network: :root_project,
                                         fork_network_member: :forked_from_project,
                                         forked_from_project: [:route, :topics, :group, :project_feature, namespace: [:route, :owner]])
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def self.forks_counting_projects(projects_relation)
        projects_relation + projects_relation.map(&:forked_from_project).compact
      end
    end
  end
end

API::Entities::Project.prepend_mod_with('API::Entities::Project', with_descendants: true)
