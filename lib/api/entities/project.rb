# frozen_string_literal: true

module API
  module Entities
    class Project < ProjectDetails
      include ::API::Helpers::RelatedResourcesHelpers

      expose :container_registry_url, as: :container_registry_image_prefix, documentation: { type: 'string', example: 'registry.gitlab.example.com/gitlab/gitlab-client' }, if: ->(_, _) { Gitlab.config.registry.enabled }

      expose :_links do
        expose :self, documentation: { type: 'string', example: 'https://gitlab.example.com/api/v4/projects/4' } do |project|
          expose_url(api_v4_projects_path(id: project.id))
        end

        expose :issues, documentation: { type: 'string', example: 'https://gitlab.example.com/api/v4/projects/4/issues' }, if: ->(project, options) { issues_available?(project, options) } do |project|
          expose_url(api_v4_projects_issues_path(id: project.id))
        end

        expose :merge_requests, documentation: { type: 'string', example: 'https://gitlab.example.com/api/v4/projects/4/merge_requests' }, if: ->(project, options) { mrs_available?(project, options) } do |project|
          expose_url(api_v4_projects_merge_requests_path(id: project.id))
        end

        expose :repo_branches, documentation: { type: 'string', example: 'https://gitlab.example.com/api/v4/projects/4/repository/branches' } do |project|
          expose_url(api_v4_projects_repository_branches_path(id: project.id))
        end

        expose :labels, documentation: { type: 'string', example: 'https://gitlab.example.com/api/v4/projects/4/labels' } do |project|
          expose_url(api_v4_projects_labels_path(id: project.id))
        end

        expose :events, documentation: { type: 'string', example: 'https://gitlab.example.com/api/v4/projects/4/events' } do |project|
          expose_url(api_v4_projects_events_path(id: project.id))
        end

        expose :members, documentation: { type: 'string', example: 'https://gitlab.example.com/api/v4/projects/4/members' } do |project|
          expose_url(api_v4_projects_members_path(id: project.id))
        end

        expose :cluster_agents, documentation: { type: 'string', example: 'https://gitlab.example.com/api/v4/projects/4/cluster_agents' } do |project|
          expose_url(api_v4_projects_cluster_agents_path(id: project.id))
        end
      end

      expose :packages_enabled, documentation: { type: 'boolean' }
      expose :empty_repo?, as: :empty_repo, documentation: { type: 'boolean' }
      expose :archived?, as: :archived, documentation: { type: 'boolean' }
      expose :visibility, documentation: { type: 'string', example: 'public' }
      expose :owner, using: Entities::UserBasic, unless: ->(project, options) { project.group }
      expose :resolve_outdated_diff_discussions, documentation: { type: 'boolean' }
      expose :container_expiration_policy,
        using: Entities::ContainerExpirationPolicy,
        if: ->(project, _) { project.container_expiration_policy }
      expose :repository_object_format, documentation: { type: 'string', example: 'sha1' }

      # Expose old field names with the new permissions methods to keep API compatible
      # TODO: remove in API v5, replaced by *_access_level
      expose(:issues_enabled, documentation: { type: 'boolean' }) { |project, options| project.feature_available?(:issues, options[:current_user]) }
      expose(:merge_requests_enabled, documentation: { type: 'boolean' }) { |project, options| project.feature_available?(:merge_requests, options[:current_user]) }
      expose(:wiki_enabled, documentation: { type: 'boolean' }) { |project, options| project.feature_available?(:wiki, options[:current_user]) }
      expose(:jobs_enabled, documentation: { type: 'boolean' }) { |project, options| project.feature_available?(:builds, options[:current_user]) }
      expose(:snippets_enabled, documentation: { type: 'boolean' }) { |project, options| project.feature_available?(:snippets, options[:current_user]) }
      expose(:container_registry_enabled, documentation: { type: 'boolean' }) { |project, options| project.feature_available?(:container_registry, options[:current_user]) }
      expose(:service_desk_enabled, documentation: { type: 'boolean' }) { |project, options| ::ServiceDesk.enabled?(project) }

      expose :service_desk_address, documentation: { type: 'string', example: 'address@example.com' },
        if: ->(project, options) { Ability.allowed?(options[:current_user], :admin_issue, project) } do |project|
        ::ServiceDesk::Emails.new(project).address
      end

      expose(:can_create_merge_request_in, documentation: { type: 'boolean' }) do |project, options|
        Ability.allowed?(options[:current_user], :create_merge_request_in, project)
      end

      expose(:issues_access_level, documentation: { type: 'string', example: 'enabled' }) { |project, options| project_feature_string_access_level(project, :issues) }
      expose(:repository_access_level, documentation: { type: 'string', example: 'enabled' }) { |project, options| project_feature_string_access_level(project, :repository) }
      expose(:merge_requests_access_level, documentation: { type: 'string', example: 'enabled' }) { |project, options| project_feature_string_access_level(project, :merge_requests) }
      expose(:forking_access_level, documentation: { type: 'string', example: 'enabled' }) { |project, options| project_feature_string_access_level(project, :forking) }
      expose(:wiki_access_level, documentation: { type: 'string', example: 'enabled' }) { |project, options| project_feature_string_access_level(project, :wiki) }
      expose(:builds_access_level, documentation: { type: 'string', example: 'enabled' }) { |project, options| project_feature_string_access_level(project, :builds) }
      expose(:snippets_access_level, documentation: { type: 'string', example: 'enabled' }) { |project, options| project_feature_string_access_level(project, :snippets) }
      expose(:pages_access_level, documentation: { type: 'string', example: 'enabled' }) { |project, options| project_feature_string_access_level(project, :pages) }
      expose(:analytics_access_level, documentation: { type: 'string', example: 'enabled' }) { |project, options| project_feature_string_access_level(project, :analytics) }
      expose(:container_registry_access_level, documentation: { type: 'string', example: 'enabled' }) { |project, options| project_feature_string_access_level(project, :container_registry) }
      expose(:security_and_compliance_access_level, documentation: { type: 'string', example: 'enabled' }) { |project, options| project_feature_string_access_level(project, :security_and_compliance) }
      expose(:releases_access_level, documentation: { type: 'string', example: 'enabled' }) { |project, options| project_feature_string_access_level(project, :releases) }
      expose(:environments_access_level, documentation: { type: 'string', example: 'enabled' }) { |project, options| project_feature_string_access_level(project, :environments) }
      expose(:feature_flags_access_level, documentation: { type: 'string', example: 'enabled' }) { |project, options| project_feature_string_access_level(project, :feature_flags) }
      expose(:infrastructure_access_level, documentation: { type: 'string', example: 'enabled' }) { |project, options| project_feature_string_access_level(project, :infrastructure) }
      expose(:monitor_access_level, documentation: { type: 'string', example: 'enabled' }) { |project, options| project_feature_string_access_level(project, :monitor) }
      expose(:model_experiments_access_level, documentation: { type: 'string', example: 'enabled' }) { |project, options| project_feature_string_access_level(project, :model_experiments) }
      expose(:model_registry_access_level, documentation: { type: 'string', example: 'enabled' }) { |project, options| project_feature_string_access_level(project, :model_registry) }

      expose(:emails_disabled, documentation: { type: 'boolean' }) { |project, options| project.emails_disabled? }
      expose :emails_enabled, documentation: { type: 'boolean' }

      expose :shared_runners_enabled, documentation: { type: 'boolean' }
      expose :lfs_enabled?, as: :lfs_enabled, documentation: { type: 'boolean' }
      expose :creator_id, documentation: { type: 'integer', example: 1 }
      expose :mr_default_target_self, if: ->(project) { project.forked? }, documentation: { type: 'boolean' }

      expose :import_url, documentation: { type: 'string', example: 'https://gitlab.com/gitlab/gitlab.git' }, if: ->(project, options) { Ability.allowed?(options[:current_user], :admin_project, project) } do |project|
        project[:import_url]
      end
      expose :import_type, documentation: { type: 'string', example: 'git' }, if: ->(project, options) { Ability.allowed?(options[:current_user], :admin_project, project) }
      expose :import_status, documentation: { type: 'string', example: 'none' }
      expose :import_error, documentation: { type: 'string', example: 'Import error' }, if: ->(_project, options) { options[:user_can_admin_project] } do |project|
        project.import_state&.last_error
      end
      expose :open_issues_count, documentation: { type: 'integer', example: 1 }, if: ->(project, options) { project.feature_available?(:issues, options[:current_user]) }
      expose :description_html, documentation: { type: 'string' }
      expose :updated_at, documentation: { type: 'dateTime', example: '2020-05-07T04:27:17.016Z' }

      with_options if: ->(_, _) { Ability.allowed?(options[:current_user], :admin_project, project) } do
        # CI/CD Settings
        expose :ci_default_git_depth, documentation: { type: 'integer', example: 20 }
        expose :ci_delete_pipelines_in_seconds, documentation: { type: 'integer', example: 86400 }
        expose :ci_forward_deployment_enabled, documentation: { type: 'boolean' }
        expose :ci_forward_deployment_rollback_allowed, documentation: { type: 'boolean' }
        expose(:ci_job_token_scope_enabled, documentation: { type: 'boolean' }) { |p, _| p.ci_outbound_job_token_scope_enabled? }
        expose :ci_separated_caches, documentation: { type: 'boolean' }
        expose :ci_allow_fork_pipelines_to_run_in_parent_project, documentation: { type: 'boolean' }
        expose :ci_id_token_sub_claim_components, documentation: { is_array: true, type: 'string' }
        expose :build_git_strategy, documentation: { type: 'string', example: 'fetch' } do |project, options|
          project.build_allow_git_fetch ? 'fetch' : 'clone'
        end
        expose :keep_latest_artifacts_available?, as: :keep_latest_artifact, documentation: { type: 'boolean' }
        expose :restrict_user_defined_variables, documentation: { type: 'boolean' }
        expose :ci_pipeline_variables_minimum_override_role, documentation: { type: 'string' }
        expose :runners_token, documentation: { type: 'string', example: 'b8547b1dc37721d05889db52fa2f02' }
        expose :runner_token_expiration_interval, documentation: { type: 'integer', example: 3600 }
        expose :group_runners_enabled, documentation: { type: 'boolean' }
        expose :auto_cancel_pending_pipelines, documentation: { type: 'string', example: 'enabled' }
        expose :build_timeout, documentation: { type: 'integer', example: 3600 }
        expose :auto_devops_enabled?, as: :auto_devops_enabled, documentation: { type: 'boolean' }
        expose :auto_devops_deploy_strategy, documentation: { type: 'string', example: 'continuous' } do |project, options|
          project.auto_devops.nil? ? 'continuous' : project.auto_devops.deploy_strategy
        end
        expose :ci_push_repository_for_job_token_allowed, documentation: { type: 'boolean' }
      end

      expose :ci_config_path, documentation: { type: 'string', example: '' }, if: ->(project, options) { Ability.allowed?(options[:current_user], :read_code, project) }
      expose :public_builds, as: :public_jobs, documentation: { type: 'boolean' }

      expose :shared_with_groups, documentation: { is_array: true } do |project, options|
        user = options[:current_user]

        SharedGroupWithProject.represent(project.visible_group_links(for_user: user), options)
      end

      expose :only_allow_merge_if_pipeline_succeeds, documentation: { type: 'boolean' }
      expose :allow_merge_on_skipped_pipeline, documentation: { type: 'boolean' }
      expose :request_access_enabled, documentation: { type: 'boolean' }
      expose :only_allow_merge_if_all_discussions_are_resolved, documentation: { type: 'boolean' }
      expose :remove_source_branch_after_merge, documentation: { type: 'boolean' }
      expose :printing_merge_request_link_enabled, documentation: { type: 'boolean' }
      expose :merge_method, documentation: { type: 'string', example: 'merge' }
      expose :squash_option, documentation: { type: 'string', example: 'default_off' }
      expose :enforce_auth_checks_on_uploads, documentation: { type: 'boolean' }
      expose :suggestion_commit_message, documentation: { type: 'string', example: 'Suggestion message' }
      expose :merge_commit_template, documentation: { type: 'string', example: '%(title)' }
      expose :squash_commit_template, documentation: { type: 'string', example: '%(source_branch)' }
      expose :issue_branch_template, documentation: { type: 'string', example: '%(title)' }
      expose :statistics, using: 'API::Entities::ProjectStatistics', if: ->(project, options) {
        options[:statistics] && Ability.allowed?(options[:current_user], :read_statistics, project)
      }
      expose :warn_about_potentially_unwanted_characters, documentation: { type: 'boolean' }

      expose :autoclose_referenced_issues, documentation: { type: 'boolean' }

      expose :max_artifacts_size, documentation: { type: 'integer' }

      # rubocop: disable CodeReuse/ActiveRecord
      def self.preload_resource(project)
        ActiveRecord::Associations::Preloader.new(records: [project], associations: { project_group_links: { group: :route } }).call
      end

      def self.preload_relation(projects_relation, options = {})
        # Preloading topics, should be done with using only `:topics`,
        # as `:topics` are defined as: `has_many :topics, through: :project_topics`
        # N+1 is solved then by using `subject.topics.map(&:name)`
        # MR describing the solution: https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/20555
        super(projects_relation).preload(group: :namespace_settings)
                                .preload(:ci_cd_settings)
                                .preload(:project_setting)
                                .preload(:container_expiration_policy)
                                .preload(:auto_devops)
                                .preload(:project_repository)
                                .preload(:service_desk_setting)
                                .preload(project_group_links: { group: :route },
                                  fork_network: :root_project,
                                  fork_network_member: :forked_from_project)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def self.execute_batch_counting(projects_relation)
        # Call the count methods on every project, so the BatchLoader would load them all at
        # once when the entities are rendered
        projects_relation.each(&:open_issues_count)

        super
      end
    end
  end
end

API::Entities::Project.prepend_mod_with('API::Entities::Project', with_descendants: true)
