# frozen_string_literal: true

module Projects
  module Security
    class ConfigurationPresenter < Gitlab::View::Presenter::Delegated
      include AutoDevopsHelper
      include ::Security::LatestPipelineInformation

      presents ::Project, as: :project

      def to_h
        {
          auto_devops_enabled: auto_devops_source?,
          auto_devops_help_page_path: help_page_path('topics/autodevops/index'),
          auto_devops_path: auto_devops_settings_path(project),
          can_enable_auto_devops: can_enable_auto_devops?,
          features: features,
          help_page_path: help_page_path('user/application_security/index'),
          latest_pipeline_path: latest_pipeline_path,
          # TODO: gitlab_ci_present will incorrectly report `false` if the CI/CD configuration file name
          # has been customized and a file with the given custom name exists in the repo. This edge case
          # will be addressed in https://gitlab.com/gitlab-org/gitlab/-/issues/342465
          gitlab_ci_present: project.repository.gitlab_ci_yml.present?,
          gitlab_ci_history_path: gitlab_ci_history_path,
          auto_fix_enabled: autofix_enabled,
          can_toggle_auto_fix_settings: can_toggle_autofix,
          auto_fix_user_path: auto_fix_user_path,
          security_training_enabled: project.security_training_available?
        }
      end

      def to_html_data_attribute
        data = to_h
        data[:features] = data[:features].to_json
        data[:auto_fix_enabled] = data[:auto_fix_enabled].to_json

        data
      end

      private

      def autofix_enabled; end

      def auto_fix_user_path; end

      def can_enable_auto_devops?
        feature_available?(:builds, current_user) &&
          can?(current_user, :admin_project, self) &&
          !archived?
      end

      def can_toggle_autofix; end

      def gitlab_ci_history_path
        return '' if project.empty_repo?

        gitlab_ci = ::Gitlab::FileDetector::PATTERNS[:gitlab_ci]
        ::Gitlab::Routing.url_helpers.project_blame_path(project, File.join(project.default_branch_or_main, gitlab_ci))
      end

      def features
        scans = scan_types.map do |scan_type|
          scan(scan_type, configured: scanner_enabled?(scan_type))
        end

        # These scans are "fake" (non job) entries. Add them manually.
        scans << scan(:corpus_management, configured: true)
        scans << scan(:dast_profiles, configured: true)
      end

      def latest_pipeline_path
        return help_page_path('ci/pipelines/index') unless latest_default_branch_pipeline

        project_pipeline_path(self, latest_default_branch_pipeline)
      end

      def scan(type, configured: false)
        scan = ::Gitlab::Security::ScanConfiguration.new(project: project, type: type, configured: configured)

        {
          type: scan.type,
          configured: scan.configured?,
          configuration_path: scan.configuration_path,
          available: scan.available?,
          can_enable_by_merge_request: scan.can_enable_by_merge_request?,
          meta_info_path: scan.meta_info_path
        }
      end

      def scan_types
        ::Security::SecurityJobsFinder.allowed_job_types + ::Security::LicenseComplianceJobsFinder.allowed_job_types
      end

      def project_settings
        project.security_setting
      end
    end
  end
end

Projects::Security::ConfigurationPresenter.prepend_mod_with('Projects::Security::ConfigurationPresenter')
