# frozen_string_literal: true

module API
  module Helpers
    module ProjectsHelpers
      extend ActiveSupport::Concern
      extend Grape::API::Helpers

      STATISTICS_SORT_PARAMS = %w[storage_size repository_size wiki_size packages_size].freeze

      params :optional_project_params_ce do
        optional :description, type: String, desc: 'The description of the project'
        optional :build_git_strategy, type: String, values: %w[fetch clone], desc: 'The Git strategy. Defaults to `fetch`'
        optional :build_timeout, type: Integer, desc: 'Build timeout'
        optional :auto_cancel_pending_pipelines, type: String, values: %w[disabled enabled], desc: 'Auto-cancel pending pipelines'
        optional :ci_config_path, type: String, desc: 'The path to CI config file. Defaults to `.gitlab-ci.yml`'
        optional :service_desk_enabled, type: Boolean, desc: 'Disable or enable the service desk'

        # TODO: remove in API v5, replaced by *_access_level
        optional :issues_enabled, type: Boolean, desc: 'Flag indication if the issue tracker is enabled'
        optional :merge_requests_enabled, type: Boolean, desc: 'Flag indication if merge requests are enabled'
        optional :wiki_enabled, type: Boolean, desc: 'Flag indication if the wiki is enabled'
        optional :jobs_enabled, type: Boolean, desc: 'Flag indication if jobs are enabled'
        optional :snippets_enabled, type: Boolean, desc: 'Flag indication if snippets are enabled'

        optional :issues_access_level, type: String, values: %w[disabled private enabled], desc: 'Issues access level. One of `disabled`, `private` or `enabled`'
        optional :repository_access_level, type: String, values: %w[disabled private enabled], desc: 'Repository access level. One of `disabled`, `private` or `enabled`'
        optional :merge_requests_access_level, type: String, values: %w[disabled private enabled], desc: 'Merge requests access level. One of `disabled`, `private` or `enabled`'
        optional :forking_access_level, type: String, values: %w[disabled private enabled], desc: 'Forks access level. One of `disabled`, `private` or `enabled`'
        optional :wiki_access_level, type: String, values: %w[disabled private enabled], desc: 'Wiki access level. One of `disabled`, `private` or `enabled`'
        optional :builds_access_level, type: String, values: %w[disabled private enabled], desc: 'Builds access level. One of `disabled`, `private` or `enabled`'
        optional :snippets_access_level, type: String, values: %w[disabled private enabled], desc: 'Snippets access level. One of `disabled`, `private` or `enabled`'
        optional :pages_access_level, type: String, values: %w[disabled private enabled public], desc: 'Pages access level. One of `disabled`, `private`, `enabled` or `public`'
        optional :analytics_access_level, type: String, values: %w[disabled private enabled], desc: 'Analytics access level. One of `disabled`, `private` or `enabled`'
        optional :container_registry_access_level, type: String, values: %w[disabled private enabled], desc: 'Controls visibility of the container registry. One of `disabled`, `private` or `enabled`. `private` will make the container registry accessible only to project members (reporter role and above). `enabled` will make the container registry accessible to everyone who has access to the project. `disabled` will disable the container registry'
        optional :security_and_compliance_access_level, type: String, values: %w[disabled private enabled], desc: 'Security and compliance access level. One of `disabled`, `private` or `enabled`'
        optional :releases_access_level, type: String, values: %w[disabled private enabled], desc: 'Releases access level. One of `disabled`, `private` or `enabled`'
        optional :environments_access_level, type: String, values: %w[disabled private enabled], desc: 'Environments access level. One of `disabled`, `private` or `enabled`'
        optional :feature_flags_access_level, type: String, values: %w[disabled private enabled], desc: 'Feature flags access level. One of `disabled`, `private` or `enabled`'
        optional :infrastructure_access_level, type: String, values: %w[disabled private enabled], desc: 'Infrastructure access level. One of `disabled`, `private` or `enabled`'
        optional :monitor_access_level, type: String, values: %w[disabled private enabled], desc: 'Monitor access level. One of `disabled`, `private` or `enabled`'
        optional :model_experiments_access_level, type: String, values: %w[disabled private enabled], desc: 'Model experiments access level. One of `disabled`, `private` or `enabled`'
        optional :model_registry_access_level, type: String, values: %w[disabled private enabled], desc: 'Model registry access level. One of `disabled`, `private` or `enabled`'

        optional :emails_disabled, type: Boolean, desc: 'Deprecated: Use emails_enabled instead.'
        optional :emails_enabled, type: Boolean, desc: 'Enable email notifications'
        optional :show_default_award_emojis, type: Boolean, desc: 'Show default award emojis'
        optional :show_diff_preview_in_email, type: Boolean, desc: 'Include the code diff preview in merge request notification emails'
        optional :warn_about_potentially_unwanted_characters, type: Boolean, desc: 'Warn about Potentially Unwanted Characters'
        optional :enforce_auth_checks_on_uploads, type: Boolean, desc: 'Enforce auth check on uploads'
        optional :shared_runners_enabled, type: Boolean, desc: 'Flag indication if shared runners are enabled for that project'
        optional :group_runners_enabled, type: Boolean, desc: 'Flag indication if group runners are enabled for that project'
        optional :resolve_outdated_diff_discussions, type: Boolean, desc: 'Automatically resolve merge request diff threads on lines changed with a push'
        optional :remove_source_branch_after_merge, type: Boolean, desc: 'Remove the source branch by default after merge'
        optional :container_registry_enabled, type: Boolean, desc: 'Deprecated: Use :container_registry_access_level instead. Flag indication if the container registry is enabled for that project'
        optional :container_expiration_policy_attributes, type: Hash do
          use :optional_container_expiration_policy_params
        end
        optional :lfs_enabled, type: Boolean, desc: 'Flag indication if Git LFS is enabled for that project'
        optional :visibility, type: String, values: Gitlab::VisibilityLevel.string_values, desc: 'The visibility of the project.'
        optional :public_builds, type: Boolean, desc: 'Deprecated: Use public_jobs instead.'
        optional :public_jobs, type: Boolean, desc: 'Perform public builds'
        optional :request_access_enabled, type: Boolean, desc: 'Allow users to request member access'
        optional :only_allow_merge_if_pipeline_succeeds, type: Boolean, desc: 'Only allow to merge if builds succeed'
        optional :allow_merge_on_skipped_pipeline, type: Boolean, desc: 'Allow to merge if pipeline is skipped'
        optional :only_allow_merge_if_all_discussions_are_resolved, type: Boolean, desc: 'Only allow to merge if all threads are resolved'
        optional :tag_list, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'Deprecated: Use :topics instead'
        optional :topics, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'The list of topics for a project'
        optional :avatar, type: ::API::Validations::Types::WorkhorseFile, desc: 'Avatar image for project', documentation: { type: 'file' }
        optional :printing_merge_request_link_enabled, type: Boolean, desc: 'Show link to create/view merge request when pushing from the command line'
        optional :merge_method, type: String, values: %w[ff rebase_merge merge], desc: 'The merge method used when merging merge requests'
        optional :suggestion_commit_message, type: String, desc: 'The commit message used to apply merge request suggestions'
        optional :merge_commit_template, type: String, desc: 'Template used to create merge commit message'
        optional :squash_commit_template, type: String, desc: 'Template used to create squash commit message'
        optional :issue_branch_template, type: String, desc: 'Template used to create a branch from an issue'
        optional :auto_devops_enabled, type: Boolean, desc: 'Flag indication if Auto DevOps is enabled'
        optional :auto_devops_deploy_strategy, type: String, values: %w[continuous manual timed_incremental], desc: 'Auto Deploy strategy'
        optional :autoclose_referenced_issues, type: Boolean, desc: 'Flag indication if referenced issues auto-closing is enabled'
        optional :repository_storage, type: String, desc: 'Which storage shard the repository is on. Available only to admins'
        optional :packages_enabled, type: Boolean, desc: 'Enable project packages feature'
        optional :squash_option, type: String, values: %w[never always default_on default_off], desc: 'Squash default for project. One of `never`, `always`, `default_on`, or `default_off`.'
        optional :mr_default_target_self, type: Boolean, desc: 'Merge requests of this forked project targets itself by default'
        optional :warn_about_potentially_unwanted_characters, type: Boolean, desc: 'Warn about potentially unwanted characters'
      end

      params :optional_project_params_ee do
      end

      params :optional_project_params do
        use :optional_project_params_ce
        use :optional_project_params_ee
      end

      params :optional_create_project_params_ce do
        optional :repository_object_format, type: String, values: %w[sha1 sha256], desc: 'The object format of the project repository'
        optional :initialize_with_readme, type: Boolean, desc: "Initialize a project with a README.md"
      end

      params :optional_create_project_params_ee do
      end

      params :optional_create_project_params do
        use :optional_project_params
        use :optional_create_project_params_ce
        use :optional_create_project_params_ee
      end

      params :optional_filter_params_ee do
      end

      params :optional_update_params_ce do
        optional :ci_default_git_depth, type: Integer, desc: 'Default number of revisions for shallow cloning'
        optional :keep_latest_artifact, type: Boolean, desc: 'Indicates if the latest artifact should be kept for this project.'
        optional :ci_forward_deployment_enabled, type: Boolean, desc: 'Prevent older deployment jobs that are still pending'
        optional :ci_forward_deployment_rollback_allowed, type: Boolean, desc: 'Allow job retries for rollback deployments'
        optional :ci_allow_fork_pipelines_to_run_in_parent_project, type: Boolean, desc: 'Allow fork merge request pipelines to run in parent project'
        optional :ci_separated_caches, type: Boolean, desc: 'Enable or disable separated caches based on branch protection.'
        optional :restrict_user_defined_variables, type: Boolean, desc: 'Restrict use of user-defined variables when triggering a pipeline'
        optional :ci_pipeline_variables_minimum_override_role, values: %w[no_one_allowed developer maintainer owner], type: String, desc: 'Limit ability to override CI/CD variables when triggering a pipeline to only users with at least the set minimum role'
        optional :ci_push_repository_for_job_token_allowed, type: Boolean, desc: "Allow pushing to this project's repository by authenticating with a CI/CD job token generated in this project."
        optional :ci_id_token_sub_claim_components, type: Array[String], values: %w[project_path ref_type ref], desc: 'Claims that will be used to build the sub claim in id tokens'
        optional :ci_delete_pipelines_in_seconds, type: Integer, desc: 'Pipelines older than the configured time are deleted'
        optional :max_artifacts_size, type: Integer, desc: "Set the maximum file size for each job's artifacts"
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

      params :share_project_params_ee do
        # Overriden in EE
      end

      def self.update_params_at_least_one_of
        [
          :allow_merge_on_skipped_pipeline,
          :analytics_access_level,
          :autoclose_referenced_issues,
          :auto_devops_enabled,
          :auto_devops_deploy_strategy,
          :auto_cancel_pending_pipelines,
          :build_git_strategy,
          :build_timeout,
          :builds_access_level,
          :ci_config_path,
          :ci_default_git_depth,
          :ci_allow_fork_pipelines_to_run_in_parent_project,
          :ci_forward_deployment_enabled,
          :ci_forward_deployment_rollback_allowed,
          :ci_separated_caches,
          :container_registry_access_level,
          :container_expiration_policy_attributes,
          :default_branch,
          :description,
          :emails_disabled, # deprecated
          :emails_enabled,
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
          :public_builds, # deprecated
          :public_jobs,
          :remove_source_branch_after_merge,
          :repository_access_level,
          :request_access_enabled,
          :resolve_outdated_diff_discussions,
          :restrict_user_defined_variables,
          :show_diff_preview_in_email,
          :security_and_compliance_access_level,
          :squash_option,
          :shared_runners_enabled,
          :group_runners_enabled,
          :snippets_access_level,
          :tag_list,
          :topics,
          :visibility,
          :wiki_access_level,
          :avatar,
          :suggestion_commit_message,
          :merge_commit_template,
          :squash_commit_template,
          :issue_branch_template,
          :repository_storage,
          :packages_enabled,
          :service_desk_enabled,
          :keep_latest_artifact,
          :mr_default_target_self,
          :enforce_auth_checks_on_uploads,
          :releases_access_level,
          :environments_access_level,
          :feature_flags_access_level,
          :infrastructure_access_level,
          :monitor_access_level,
          :model_experiments_access_level,
          :model_registry_access_level,
          :warn_about_potentially_unwanted_characters,
          :ci_pipeline_variables_minimum_override_role,
          :ci_push_repository_for_job_token_allowed,
          :ci_delete_pipelines_in_seconds,
          :max_artifacts_size,

          # TODO: remove in API v5, replaced by *_access_level
          :issues_enabled,
          :jobs_enabled,
          :merge_requests_enabled,
          :wiki_enabled,
          :snippets_enabled,
          :container_registry_enabled
        ]
      end

      def filter_attributes_using_license!(attrs); end

      def validate_git_import_url!(import_url)
        return if import_url.blank?

        result = Import::ValidateRemoteGitEndpointService.new(url: import_url).execute # network call

        if result.error?
          render_api_error!(result.message, 422)
        end
      end
    end
  end
end

API::Helpers::ProjectsHelpers.prepend_mod_with('API::Helpers::ProjectsHelpers')
