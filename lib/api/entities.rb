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
