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
          auto_devops_help_page_path: help_page_path('topics/autodevops/_index.md'),
          auto_devops_path: auto_devops_settings_path(project),
          can_enable_auto_devops: can_enable_auto_devops?,
          features: features,
          help_page_path: help_page_path('user/application_security/_index.md'),
          latest_pipeline_path: latest_pipeline_path,
          gitlab_ci_present: project.has_ci_config_file?,
          gitlab_ci_history_path: gitlab_ci_history_path,
          security_training_enabled: project.security_training_available?,
          container_scanning_for_registry_enabled: container_scanning_for_registry_enabled,
          secret_push_protection_available: secret_push_protection_available?,
          secret_push_protection_enabled: secret_push_protection_enabled,
          secret_push_protection_licensed: secret_push_protection_licensed?,
          validity_checks_available: validity_checks_available,
          validity_checks_enabled: validity_checks_enabled,
          user_is_project_admin: user_is_project_admin?,
          can_enable_spp: can_enable_spp?,
          is_gitlab_com: gitlab_com?,
          secret_detection_configuration_path: secret_detection_configuration_path,
          license_configuration_source: license_configuration_source,
          vulnerability_training_docs_path: vulnerability_training_docs_path,
          upgrade_path: upgrade_path,
          group_full_path: group_full_path,
          can_apply_profiles: can_apply_profiles?,
          can_read_attributes: can_read_attributes?,
          can_manage_attributes: can_manage_attributes?,
          security_scan_profiles_licensed: security_scan_profiles_licensed?,
          group_manage_attributes_path: group_manage_attributes_path,
          max_tracked_refs: max_tracked_refs
        }
      end

      def to_html_data_attribute
        data = to_h
        data[:features] = data[:features].to_json

        data
      end

      private

      def secret_push_protection_available?
        Gitlab::CurrentSettings.current_application_settings.secret_push_protection_available
      end

      def secret_push_protection_licensed?
        project.licensed_feature_available?(:secret_push_protection)
      end

      def security_scan_profiles_licensed?
        project.licensed_feature_available?(:security_scan_profiles)
      end

      def can_enable_auto_devops?
        feature_available?(:builds, current_user) &&
          user_is_project_admin? &&
          !archived?
      end

      def user_is_project_admin?
        can?(current_user, :admin_security_testing, self)
      end

      def can_enable_spp?
        can?(current_user, :enable_secret_push_protection, self)
      end

      def gitlab_ci_history_path
        return '' if project.empty_repo?

        ::Gitlab::Routing.url_helpers.project_blame_path(
          project, File.join(project.default_branch_or_main, project.ci_config_path_or_default))
      end

      def features
        scans = scan_types.map do |scan_type|
          scan(scan_type, configured: scanner_enabled?(scan_type))
        end

        # These scans are "fake" (non job) entries. Add them manually.
        scans << scan(:corpus_management, configured: true)
        scans << scan(:dast_profiles, configured: true)
        scans << scan(:license_information_source, configured: true)

        # Add SPP before secret detection
        secret_detection_index = scans.index { |scan| scan[:type] == :secret_detection } || -1
        scans.insert(secret_detection_index, scan(:secret_push_protection, configured: true))

        scans
      end

      def latest_pipeline_path
        return help_page_path('ci/pipelines/_index.md') unless latest_default_branch_pipeline

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
          meta_info_path: scan.meta_info_path,
          on_demand_available: scan.on_demand_available?,
          security_features: scan.security_features
        }
      end

      def scan_types
        Enums::Security.analyzer_types.keys + ::Security::LicenseComplianceJobsFinder.allowed_job_types
      end

      def project_settings
        project.security_setting
      end

      def vulnerability_training_docs_path
        help_page_path(
          'user/application_security/vulnerabilities/_index.md',
          anchor: 'enable-security-training-for-vulnerabilities'
        )
      end

      def upgrade_path
        promo_pricing_url
      end

      def group_full_path
        root_group.full_path if root_group
      end

      def can_apply_profiles?
        return false unless root_group

        can?(current_user, :apply_security_scan_profiles, project)
      end

      def can_read_attributes?
        return false unless root_group

        can?(current_user, :read_security_attribute, root_group)
      end

      def can_manage_attributes?
        return false unless root_group

        can?(current_user, :admin_security_attributes, root_group)
      end

      def root_group
        @root_group ||= project.root_ancestor if project.root_ancestor.is_a?(Group)
      end

      def gitlab_com?; end
      def max_tracked_refs; end
      def validity_checks_available; end
      def validity_checks_enabled; end
      def container_scanning_for_registry_enabled; end
      def secret_push_protection_enabled; end
      def secret_detection_configuration_path; end
      def license_configuration_source; end
      def group_manage_attributes_path; end
    end
  end
end

Projects::Security::ConfigurationPresenter.prepend_mod_with('Projects::Security::ConfigurationPresenter')
