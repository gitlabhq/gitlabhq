# frozen_string_literal: true

module API
  module Helpers
    module ProjectsHelpers
      extend ActiveSupport::Concern
      extend Grape::API::Helpers

      STATISTICS_SORT_PARAMS = %w[storage_size repository_size wiki_size packages_size].freeze

      params :optional_project_params_ce do
        optional :description, type: String, desc: 'The description of the project'
        optional :build_git_strategy, type: String, values: %w(fetch clone), desc: 'The Git strategy. Defaults to `fetch`'
        optional :build_timeout, type: Integer, desc: 'Build timeout'
        optional :auto_cancel_pending_pipelines, type: String, values: %w(disabled enabled), desc: 'Auto-cancel pending pipelines'
        optional :build_coverage_regex, type: String, desc: 'Test coverage parsing'
        optional :ci_config_path, type: String, desc: 'The path to CI config file. Defaults to `.gitlab-ci.yml`'
        optional :service_desk_enabled, type: Boolean, desc: 'Disable or enable the service desk'
        optional :keep_latest_artifact, type: Boolean, desc: 'Indicates if the latest artifact should be kept for this project.'

        # TODO: remove in API v5, replaced by *_access_level
        optional :issues_enabled, type: Boolean, desc: 'Flag indication if the issue tracker is enabled'
        optional :merge_requests_enabled, type: Boolean, desc: 'Flag indication if merge requests are enabled'
        optional :wiki_enabled, type: Boolean, desc: 'Flag indication if the wiki is enabled'
        optional :jobs_enabled, type: Boolean, desc: 'Flag indication if jobs are enabled'
        optional :snippets_enabled, type: Boolean, desc: 'Flag indication if snippets are enabled'

        optional :issues_access_level, type: String, values: %w(disabled private enabled), desc: 'Issues access level. One of `disabled`, `private` or `enabled`'
        optional :repository_access_level, type: String, values: %w(disabled private enabled), desc: 'Repository access level. One of `disabled`, `private` or `enabled`'
        optional :merge_requests_access_level, type: String, values: %w(disabled private enabled), desc: 'Merge requests access level. One of `disabled`, `private` or `enabled`'
        optional :forking_access_level, type: String, values: %w(disabled private enabled), desc: 'Forks access level. One of `disabled`, `private` or `enabled`'
        optional :wiki_access_level, type: String, values: %w(disabled private enabled), desc: 'Wiki access level. One of `disabled`, `private` or `enabled`'
        optional :builds_access_level, type: String, values: %w(disabled private enabled), desc: 'Builds access level. One of `disabled`, `private` or `enabled`'
        optional :snippets_access_level, type: String, values: %w(disabled private enabled), desc: 'Snippets access level. One of `disabled`, `private` or `enabled`'
        optional :pages_access_level, type: String, values: %w(disabled private enabled public), desc: 'Pages access level. One of `disabled`, `private`, `enabled` or `public`'
        optional :operations_access_level, type: String, values: %w(disabled private enabled), desc: 'Operations access level. One of `disabled`, `private` or `enabled`'
        optional :analytics_access_level, type: String, values: %w(disabled private enabled), desc: 'Analytics access level. One of `disabled`, `private` or `enabled`'

        optional :emails_disabled, type: Boolean, desc: 'Disable email notifications'
        optional :show_default_award_emojis, type: Boolean, desc: 'Show default award emojis'
        optional :shared_runners_enabled, type: Boolean, desc: 'Flag indication if shared runners are enabled for that project'
        optional :resolve_outdated_diff_discussions, type: Boolean, desc: 'Automatically resolve merge request diffs discussions on lines changed with a push'
        optional :remove_source_branch_after_merge, type: Boolean, desc: 'Remove the source branch by default after merge'
        optional :container_registry_enabled, type: Boolean, desc: 'Flag indication if the container registry is enabled for that project'
        optional :container_expiration_policy_attributes, type: Hash do
          use :optional_container_expiration_policy_params
        end
        optional :lfs_enabled, type: Boolean, desc: 'Flag indication if Git LFS is enabled for that project'
        optional :visibility, type: String, values: Gitlab::VisibilityLevel.string_values, desc: 'The visibility of the project.'
        optional :public_builds, type: Boolean, desc: 'Perform public builds'
        optional :request_access_enabled, type: Boolean, desc: 'Allow users to request member access'
        optional :only_allow_merge_if_pipeline_succeeds, type: Boolean, desc: 'Only allow to merge if builds succeed'
        optional :allow_merge_on_skipped_pipeline, type: Boolean, desc: 'Allow to merge if pipeline is skipped'
        optional :only_allow_merge_if_all_discussions_are_resolved, type: Boolean, desc: 'Only allow to merge if all discussions are resolved'
        optional :tag_list, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'Deprecated: Use :topics instead'
        optional :topics, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'The list of topics for a project'
        # TODO: remove rubocop disable - https://gitlab.com/gitlab-org/gitlab/issues/14960
        optional :avatar, type: File, desc: 'Avatar image for project' # rubocop:disable Scalability/FileUploads
        optional :printing_merge_request_link_enabled, type: Boolean, desc: 'Show link to create/view merge request when pushing from the command line'
        optional :merge_method, type: String, values: %w(ff rebase_merge merge), desc: 'The merge method used when merging merge requests'
        optional :suggestion_commit_message, type: String, desc: 'The commit message used to apply merge request suggestions'
        optional :initialize_with_readme, type: Boolean, desc: "Initialize a project with a README.md"
        optional :ci_default_git_depth, type: Integer, desc: 'Default number of revisions for shallow cloning'
        optional :auto_devops_enabled, type: Boolean, desc: 'Flag indication if Auto DevOps is enabled'
        optional :auto_devops_deploy_strategy, type: String, values: %w(continuous manual timed_incremental), desc: 'Auto Deploy strategy'
        optional :autoclose_referenced_issues, type: Boolean, desc: 'Flag indication if referenced issues auto-closing is enabled'
        optional :repository_storage, type: String, desc: 'Which storage shard the repository is on. Available only to admins'
        optional :packages_enabled, type: Boolean, desc: 'Enable project packages feature'
        optional :squash_option, type: String, values: %w(never always default_on default_off), desc: 'Squash default for project. One of `never`, `always`, `default_on`, or `default_off`.'
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

      params :optional_update_params_ce do
        optional :ci_forward_deployment_enabled, type: Boolean, desc: 'Skip older deployment jobs that are still pending'
        optional :restrict_user_defined_variables, type: Boolean, desc: 'Restrict use of user-defined variables when triggering a pipeline'
      end

      params :optional_update_params_ee do
      end

      params :optional_update_params do
        use :optional_update_params_ce
        use :optional_update_params_ee
      end

      params :optional_container_expiration_policy_params do
        optional :cadence, type: String, desc: 'Container expiration policy cadence for recurring job'
        optional :keep_n, type: Integer, desc: 'Container expiration policy number of images to keep'
        optional :older_than, type: String, desc: 'Container expiration policy remove images older than value'
        optional :name_regex, type: String, desc: 'Container expiration policy regex for image removal'
        optional :name_regex_keep, type: String, desc: 'Container expiration policy regex for image retention'
        optional :enabled, type: Boolean, desc: 'Flag indication if container expiration policy is enabled'
      end

      def self.update_params_at_least_one_of
        [
          :allow_merge_on_skipped_pipeline,
          :autoclose_referenced_issues,
          :auto_devops_enabled,
          :auto_devops_deploy_strategy,
          :auto_cancel_pending_pipelines,
          :build_coverage_regex,
          :build_git_strategy,
          :build_timeout,
          :builds_access_level,
          :ci_config_path,
          :ci_default_git_depth,
          :ci_forward_deployment_enabled,
          :container_registry_enabled,
          :container_expiration_policy_attributes,
          :default_branch,
          :description,
          :emails_disabled,
          :forking_access_level,
          :issues_access_level,
          :lfs_enabled,
          :merge_pipelines_enabled,
          :merge_requests_access_level,
          :merge_requests_template,
          :merge_trains_enabled,
          :merge_method,
          :name,
          :only_allow_merge_if_all_discussions_are_resolved,
          :only_allow_merge_if_pipeline_succeeds,
          :pages_access_level,
          :path,
          :printing_merge_request_link_enabled,
          :public_builds,
          :remove_source_branch_after_merge,
          :repository_access_level,
          :request_access_enabled,
          :resolve_outdated_diff_discussions,
          :restrict_user_defined_variables,
          :squash_option,
          :shared_runners_enabled,
          :snippets_access_level,
          :tag_list,
          :topics,
          :visibility,
          :wiki_access_level,
          :avatar,
          :suggestion_commit_message,
          :repository_storage,
          :compliance_framework_setting,
          :packages_enabled,
          :service_desk_enabled,
          :keep_latest_artifact,

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

API::Helpers::ProjectsHelpers.prepend_mod_with('API::Helpers::ProjectsHelpers')
