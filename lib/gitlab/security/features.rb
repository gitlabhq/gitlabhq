# frozen_string_literal: true

module Gitlab
  module Security
    class Features
      # rubocop: disable Metrics/AbcSize -- Generate dynamic translation as per
      # https://docs.gitlab.com/ee/development/i18n/externalization.html#keep-translations-dynamic
      def self.data
        {
          sast: {
            name: _('Static Application Security Testing (SAST)'),
            short_name: _('SAST'),
            description: _('Analyze your source code for vulnerabilities.'),
            help_path: Gitlab::Routing.url_helpers.help_page_path('user/application_security/sast/_index.md'),
            configuration_help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/sast/_index.md', anchor: 'configuration'),
            type: 'sast',
            required_permission_to_configure: :configure_security_scanner
          },
          sast_advanced: {
            name: _('GitLab Advanced SAST'),
            short_name: _('Advanced SAST'),
            description: _('Analyze your source code for vulnerabilities with the GitLab Advanced SAST analyzer.'),
            help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/sast/gitlab_advanced_sast.md'),
            configuration_help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/sast/gitlab_advanced_sast.md',
              anchor: 'configuration'),
            type: 'sast_advanced',
            required_permission_to_configure: :configure_security_scanner
          },
          sast_iac: {
            name: _('Infrastructure as Code (IaC) Scanning'),
            short_name: s_('ciReport|SAST IaC'),
            description: _('Analyze your infrastructure as code configuration files for known vulnerabilities.'),
            help_path: Gitlab::Routing.url_helpers.help_page_path('user/application_security/iac_scanning/_index.md'),
            configuration_help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/iac_scanning/_index.md',
              anchor: 'configuration'),
            type: 'sast_iac',
            required_permission_to_configure: :configure_security_scanner
          },
          dast: {
            secondary: {
              type: 'dast_profiles',
              name: _('DAST profiles'),
              description: s_('SecurityConfiguration|Manage profiles for use by DAST scans.'),
              configuration_text: s_('SecurityConfiguration|Manage DAST profiles')
            },
            name: _('Dynamic Application Security Testing (DAST)'),
            short_name: s_('ciReport|DAST'),
            description: s_('ciReport|Analyze a deployed version of your web application for known ' \
                            'vulnerabilities by examining it from the outside in. DAST works ' \
                            'by simulating external attacks on your application while it is running.'),
            help_path: Gitlab::Routing.url_helpers.help_page_path('user/application_security/dast/_index.md'),
            configuration_help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/dast/_index.md', anchor: 'enable-automatic-dast-run'),
            type: 'dast',
            anchor: 'dast',
            required_permission_to_configure: :configure_security_scanner
          },
          dependency_scanning: {
            name: _('Dependency Scanning'),
            description: _('Analyze your dependencies for known vulnerabilities.'),
            help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/dependency_scanning/_index.md'),
            configuration_help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/dependency_scanning/_index.md', anchor: 'configuration'),
            type: 'dependency_scanning',
            anchor: 'dependency-scanning',
            required_permission_to_configure: :configure_security_scanner
          },
          container_scanning: {
            name: _('Container Scanning'),
            description: _('Check your Docker images for known vulnerabilities.'),
            help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/container_scanning/_index.md'),
            configuration_help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/container_scanning/_index.md', anchor: 'configuration'),
            type: 'container_scanning',
            required_permission_to_configure: :configure_security_scanner
          },
          container_scanning_for_registry: {
            name: _('Container Scanning For Registry'),
            description: _('Run container scanning job whenever a container image with the latest tag is pushed.'),
            help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/container_scanning/_index.md', anchor: 'container-scanning-for-registry'),
            type: 'container_scanning_for_registry',
            required_permission_to_configure: :enable_container_scanning_for_registry
          },
          cvs_for_container_scanning: {
            name: _('Continuous Vulnerability Scanning for Container Scanning'),
            description: _('Automatically detects new container vulnerabilities based on SBOM data ' \
                           'when new security advisories are ingested.'),
            help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/continuous_vulnerability_scanning/_index.md'),
            type: 'cvs_for_container_scanning',
            required_permission_to_configure: :update_cvs_for_container_scanning
          },
          cvs_for_dependency_scanning: {
            name: _('Continuous Vulnerability Scanning for Dependency Scanning'),
            description: _('Automatically detects new dependency vulnerabilities based on SBOM data ' \
                           'when new security advisories are ingested.'),
            help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/continuous_vulnerability_scanning/_index.md'),
            type: 'cvs_for_dependency_scanning',
            required_permission_to_configure: :update_cvs_for_dependency_scanning
          },
          license_information_source: {
            name: _('License information source'),
            description: _('Define the preferred source for license information.'),
            help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/compliance/license_scanning_of_cyclonedx_files/_index.md',
              anchor: 'use-cyclonedx-report-as-a-source-of-license-information'),
            type: 'license_information_source',
            required_permission_to_configure: :set_license_information_source
          },
          secret_push_protection: {
            name: _('Secret push protection'),
            description: _('Block secrets such as keys and API tokens from being pushed to your repositories. ' \
                           'Secret push protection is triggered when commits are pushed to a repository. ' \
                           'If any secrets are detected, the push is blocked.'),
            help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/secret_detection/secret_push_protection/_index.md'),
            type: 'secret_push_protection',
            required_permission_to_configure: :enable_secret_push_protection
          },
          secret_detection: {
            name: _('Pipeline Secret Detection'),
            description: _('Analyze your source code and Git history for secrets by using CI/CD pipelines.'),
            help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/secret_detection/pipeline/_index.md'),
            configuration_help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/secret_detection/pipeline/_index.md', anchor: 'configuration'),
            type: 'secret_detection',
            required_permission_to_configure: :configure_security_scanner
          },
          api_fuzzing: {
            name: _('API Fuzzing'),
            description: _('Find bugs in your code with API fuzzing.'),
            help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/api_fuzzing/_index.md'),
            type: 'api_fuzzing',
            required_permission_to_configure: :configure_security_scanner
          },
          coverage_fuzzing: {
            name: _('Coverage Fuzzing'),
            description: _('Find bugs in your code with coverage-guided fuzzing.'),
            help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/coverage_fuzzing/_index.md'),
            configuration_help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/coverage_fuzzing/_index.md', anchor: 'enable-coverage-guided-fuzz-testing'),
            type: 'coverage_fuzzing',
            secondary: {
              type: 'corpus_management',
              name: _('Corpus Management'),
              description: s_('SecurityConfiguration|Manage corpus files used as seed ' \
                              'inputs with coverage-guided fuzzing.'),
              configuration_text: s_('SecurityConfiguration|Manage corpus')
            },
            required_permission_to_configure: :configure_security_scanner
          }
        }.freeze
      end
      # rubocop: enable Metrics/AbcSize
    end
  end
end
