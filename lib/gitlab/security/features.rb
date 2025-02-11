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
            type: 'sast'
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
            type: 'sast_advanced'
          },
          sast_iac: {
            name: _('Infrastructure as Code (IaC) Scanning'),
            short_name: s_('ciReport|SAST IaC'),
            description: _('Analyze your infrastructure as code configuration files for known vulnerabilities.'),
            help_path: Gitlab::Routing.url_helpers.help_page_path('user/application_security/iac_scanning/_index.md'),
            configuration_help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/iac_scanning/_index.md',
              anchor: 'configuration'),
            type: 'sast_iac'
          },
          dast: {
            badge: {
              text: _('Available on demand'),
              tooltip_text: _(
                'On-demand scans run outside of the DevOps cycle and find vulnerabilities in your projects'),
              variant: 'neutral'
            },
            secondary: {
              type: 'dast_profiles',
              name: _('DAST profiles'),
              description: s_('SecurityConfiguration|Manage profiles for use by DAST scans.'),
              configuration_text: s_('SecurityConfiguration|Manage profiles')
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
            anchor: 'dast'
          },
          dependency_scanning: {
            name: _('Dependency Scanning'),
            description: _('Analyze your dependencies for known vulnerabilities.'),
            help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/dependency_scanning/_index.md'),
            configuration_help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/dependency_scanning/_index.md', anchor: 'configuration'),
            type: 'dependency_scanning',
            anchor: 'dependency-scanning'
          },
          container_scanning: {
            name: _('Container Scanning'),
            description: _('Check your Docker images for known vulnerabilities.'),
            help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/container_scanning/_index.md'),
            configuration_help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/container_scanning/_index.md', anchor: 'configuration'),
            type: 'container_scanning'
          },
          container_scanning_for_registry: {
            name: _('Container Scanning For Registry'),
            description: _('Run container scanning job whenever a container image with the latest tag is pushed.'),
            help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/container_scanning/_index.md', anchor: 'container-scanning-for-registry'),
            type: 'container_scanning_for_registry'
          },
          secret_push_protection: {
            name: _('Secret push protection'),
            description: _('Block secrets such as keys and API tokens from being pushed to your repositories. ' \
                           'Secret push protection is triggered when commits are pushed to a repository. ' \
                           'If any secrets are detected, the push is blocked.'),
            help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/secret_detection/secret_push_protection/_index.md'),
            type: 'secret_push_protection'
          },
          secret_detection: {
            name: _('Pipeline Secret Detection'),
            description: _('Analyze your source code and Git history for secrets by using CI/CD pipelines.'),
            help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/secret_detection/pipeline/_index.md'),
            configuration_help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/secret_detection/pipeline/_index.md', anchor: 'configuration'),
            type: 'secret_detection'
          },
          api_fuzzing: {
            name: _('API Fuzzing'),
            description: _('Find bugs in your code with API fuzzing.'),
            help_path: Gitlab::Routing.url_helpers.help_page_path(
              'user/application_security/api_fuzzing/_index.md'),
            type: 'api_fuzzing'
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
            }
          }
        }.freeze
      end
      # rubocop: enable Metrics/AbcSize
    end
  end
end
