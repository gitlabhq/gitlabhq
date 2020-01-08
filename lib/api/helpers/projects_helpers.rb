# frozen_string_literal: true

module API
  module Helpers
    module ProjectsHelpers
      extend ActiveSupport::Concern
      extend Grape::API::Helpers

      params :optional_project_params_ce do
        optional :description, type: String, desc: 'The description of the project'
        optional :build_git_strategy, type: String, values: %w(fetch clone), desc: 'The Git strategy. Defaults to `fetch`'
        optional :build_timeout, type: Integer, desc: 'Build timeout'
        optional :auto_cancel_pending_pipelines, type: String, values: %w(disabled enabled), desc: 'Auto-cancel pending pipelines'
        optional :build_coverage_regex, type: String, desc: 'Test coverage parsing'
        optional :ci_config_path, type: String, desc: 'The path to CI config file. Defaults to `.gitlab-ci.yml`'

        # TODO: remove in API v5, replaced by *_access_level
        optional :issues_enabled, type: Boolean, desc: 'Flag indication if the issue tracker is enabled'
        optional :merge_requests_enabled, type: Boolean, desc: 'Flag indication if merge requests are enabled'
        optional :wiki_enabled, type: Boolean, desc: 'Flag indication if the wiki is enabled'
        optional :jobs_enabled, type: Boolean, desc: 'Flag indication if jobs are enabled'
        optional :snippets_enabled, type: Boolean, desc: 'Flag indication if snippets are enabled'

        optional :issues_access_level, type: String, values: %w(disabled private enabled), desc: 'Issues access level. One of `disabled`, `private` or `enabled`'
        optional :repository_access_level, type: String, values: %w(disabled private enabled), desc: 'Repository access level. One of `disabled`, `private` or `enabled`'
        optional :merge_requests_access_level, type: String, values: %w(disabled private enabled), desc: 'Merge requests access level. One of `disabled`, `private` or `enabled`'
        optional :wiki_access_level, type: String, values: %w(disabled private enabled), desc: 'Wiki access level. One of `disabled`, `private` or `enabled`'
        optional :builds_access_level, type: String, values: %w(disabled private enabled), desc: 'Builds access level. One of `disabled`, `private` or `enabled`'
        optional :snippets_access_level, type: String, values: %w(disabled private enabled), desc: 'Snippets access level. One of `disabled`, `private` or `enabled`'

        optional :shared_runners_enabled, type: Boolean, desc: 'Flag indication if shared runners are enabled for that project'
        optional :resolve_outdated_diff_discussions, type: Boolean, desc: 'Automatically resolve merge request diffs discussions on lines changed with a push'
        optional :remove_source_branch_after_merge, type: Boolean, desc: 'Remove the source branch by default after merge'
        optional :container_registry_enabled, type: Boolean, desc: 'Flag indication if the container registry is enabled for that project'
        optional :lfs_enabled, type: Boolean, desc: 'Flag indication if Git LFS is enabled for that project'
        optional :visibility, type: String, values: Gitlab::VisibilityLevel.string_values, desc: 'The visibility of the project.'
        optional :public_builds, type: Boolean, desc: 'Perform public builds'
        optional :request_access_enabled, type: Boolean, desc: 'Allow users to request member access'
        optional :only_allow_merge_if_pipeline_succeeds, type: Boolean, desc: 'Only allow to merge if builds succeed'
        optional :only_allow_merge_if_all_discussions_are_resolved, type: Boolean, desc: 'Only allow to merge if all discussions are resolved'
        optional :tag_list, type: Array[String], desc: 'The list of tags for a project'
        # TODO: remove rubocop disable - https://gitlab.com/gitlab-org/gitlab/issues/14960
        optional :avatar, type: File, desc: 'Avatar image for project' # rubocop:disable Scalability/FileUploads
        optional :printing_merge_request_link_enabled, type: Boolean, desc: 'Show link to create/view merge request when pushing from the command line'
        optional :merge_method, type: String, values: %w(ff rebase_merge merge), desc: 'The merge method used when merging merge requests'
        optional :initialize_with_readme, type: Boolean, desc: "Initialize a project with a README.md"
        optional :ci_default_git_depth, type: Integer, desc: 'Default number of revisions for shallow cloning'
        optional :auto_devops_enabled, type: Boolean, desc: 'Flag indication if Auto DevOps is enabled'
        optional :auto_devops_deploy_strategy, type: String, values: %w(continuous manual timed_incremental), desc: 'Auto Deploy strategy'
        optional :autoclose_referenced_issues, type: Boolean, desc: 'Flag indication if referenced issues auto-closing is enabled'
      end

      params :optional_project_params_ee do
      end

      params :optional_project_params do
        use :optional_project_params_ce
        use :optional_project_params_ee
      end

      params :optional_create_project_params_ee do
      end

      params :optional_create_project_params do
        use :optional_project_params
        use :optional_create_project_params_ee
      end

      params :optional_filter_params_ee do
      end

      params :optional_update_params_ee do
      end

      def self.update_params_at_least_one_of
        [
          :auto_devops_enabled,
          :auto_devops_deploy_strategy,
          :auto_cancel_pending_pipelines,
          :build_coverage_regex,
          :build_git_strategy,
          :build_timeout,
          :builds_access_level,
          :ci_config_path,
          :ci_default_git_depth,
          :container_registry_enabled,
          :default_branch,
          :description,
          :autoclose_referenced_issues,
          :issues_access_level,
          :lfs_enabled,
          :merge_requests_access_level,
          :merge_method,
          :name,
          :only_allow_merge_if_all_discussions_are_resolved,
          :only_allow_merge_if_pipeline_succeeds,
          :path,
          :printing_merge_request_link_enabled,
          :public_builds,
          :remove_source_branch_after_merge,
          :repository_access_level,
          :request_access_enabled,
          :resolve_outdated_diff_discussions,
          :shared_runners_enabled,
          :snippets_access_level,
          :tag_list,
          :visibility,
          :wiki_access_level,
          :avatar,

          # TODO: remove in API v5, replaced by *_access_level
          :issues_enabled,
          :jobs_enabled,
          :merge_requests_enabled,
          :wiki_enabled,
          :snippets_enabled
        ]
      end

      def filter_attributes_using_license!(attrs)
      end
    end
  end
end

API::Helpers::ProjectsHelpers.prepend_if_ee('EE::API::Helpers::ProjectsHelpers')
