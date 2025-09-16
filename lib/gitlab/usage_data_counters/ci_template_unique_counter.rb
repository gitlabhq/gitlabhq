# frozen_string_literal: true

module Gitlab::UsageDataCounters
  class CiTemplateUniqueCounter
    PREFIX = 'ci_templates'
    MIGRATED_REDIS_HLL_EVENTS = %w[
      p_ci_templates_5_minute_production_app
      p_ci_templates_android
      p_ci_templates_android_fastlane
      p_ci_templates_android_latest
      p_ci_templates_aws_cf_provision_and_deploy_ec2
      p_ci_templates_bash
      p_ci_templates_c
      p_ci_templates_chef
      p_ci_templates_clojure
      p_ci_templates_code_quality
      p_ci_templates_composer
      p_ci_templates_implicit_auto_devops
      p_ci_templates_implicit_jobs_deploy
      p_ci_templates_implicit_jobs_dast_default_branch_deploy
      p_ci_templates_maven
      p_ci_templates_nodejs
      p_ci_templates_crystal
      p_ci_templates_go
      p_ci_templates_cosign
      p_ci_templates_dart
      p_ci_templates_deploy_ecs
      p_ci_templates_diffblue_cover
      p_ci_templates_django
      p_ci_templates_docker
      p_ci_templates_dotnet
      p_ci_templates_dotnet_core
      p_ci_templates_elixir
      p_ci_templates_flutter
      p_ci_templates_getting_started
      p_ci_templates_gradle
      p_ci_templates_grails
      p_ci_templates_indeni_cloudrail
      p_ci_templates_ios_fastlane
      p_ci_templates_julia
      p_ci_templates_security_coverage_fuzzing
      p_ci_templates_security_dast_on_demand_scan
      p_ci_templates_jobs_sast
      p_ci_templates_workflows_mergerequest_pipelines
      p_ci_templates_openshift
      p_ci_templates_laravel
      p_ci_templates_pages_hugo
      p_ci_templates_terraform
      p_ci_templates_implicit_jobs_secret_detection
      p_ci_templates_jobs_sast_iac_latest
      p_ci_templates_pages_doxygen
      p_ci_templates_pages_html
      p_ci_templates_verify_load_performance_testing
      p_ci_templates_jobs_sast_iac
      p_ci_templates_npm
      p_ci_templates_pages_brunch
      p_ci_templates_pages_nanoc
      p_ci_templates_terraform_module_base
      p_ci_templates_auto_devops
      p_ci_templates_aws_deploy_ecs
      p_ci_templates_implicit_jobs_browser_performance_testing
      p_ci_templates_implicit_jobs_build
      p_ci_templates_implicit_jobs_code_intelligence
      p_ci_templates_implicit_jobs_code_quality
      p_ci_templates_implicit_jobs_container_scanning
      p_ci_templates_implicit_jobs_dependency_scanning
      p_ci_templates_implicit_jobs_deploy_ec2
      p_ci_templates_implicit_jobs_deploy_ecs
      p_ci_templates_implicit_jobs_helm_2to3
      p_ci_templates_implicit_jobs_license_scanning
      p_ci_templates_implicit_jobs_sast
      p_ci_templates_implicit_jobs_test
      p_ci_templates_implicit_security_container_scanning
      p_ci_templates_implicit_security_dast
      p_ci_templates_implicit_security_dependency_scanning
      p_ci_templates_implicit_security_license_scanning
      p_ci_templates_implicit_security_sast
      p_ci_templates_implicit_security_secret_detection
      p_ci_templates_jobs_browser_performance_testing
      p_ci_templates_jobs_browser_performance_testing_latest
      p_ci_templates_jobs_build
      p_ci_templates_jobs_build_latest
      p_ci_templates_jobs_cf_provision
      p_ci_templates_jobs_code_intelligence
      p_ci_templates_jobs_code_quality
      p_ci_templates_jobs_container_scanning
      p_ci_templates_jobs_container_scanning_latest
      p_ci_templates_jobs_dast_default_branch_deploy
      p_ci_templates_jobs_dependency_scanning
      p_ci_templates_jobs_dependency_scanning_latest
      p_ci_templates_jobs_deploy
      p_ci_templates_jobs_deploy_ec2
      p_ci_templates_jobs_deploy_ecs
      p_ci_templates_jobs_deploy_latest
      p_ci_templates_jobs_helm_2to3
      p_ci_templates_jobs_license_scanning
      p_ci_templates_jobs_license_scanning_latest
      p_ci_templates_jobs_load_performance_testing
      p_ci_templates_jobs_sast_latest
      p_ci_templates_jobs_secret_detection
      p_ci_templates_jobs_secret_detection_latest
      p_ci_templates_jobs_test
    ].freeze

    class << self
      def track_unique_project_event(project:, template:, config_source:, user:)
        expanded_template_name = expand_template_name(template)
        return unless expanded_template_name

        event_name = ci_template_event_name(expanded_template_name, config_source)
        unless MIGRATED_REDIS_HLL_EVENTS.include?(event_name)
          Gitlab::UsageDataCounters::HLLRedisCounter.track_event(event_name, values: project.id)
        end

        namespace = project.namespace
        implicit = config_source.to_s == 'auto_devops_source'

        Gitlab::InternalEvents.track_event(
          'ci_template_included',
          namespace: namespace,
          project: project,
          user: user,
          additional_properties: {
            label: template_to_event_name(expanded_template_name),
            property: implicit.to_s
          }
        )
      end

      def ci_templates(relative_base = 'lib/gitlab/ci/templates')
        Dir.glob('**/*.gitlab-ci.yml', base: Rails.root.join(relative_base))
      end

      def ci_template_event_name(template_name, config_source)
        prefix = 'implicit_' if config_source.to_s == 'auto_devops_source'

        "p_#{PREFIX}_#{prefix}#{template_to_event_name(template_name)}"
      end

      def expand_template_name(template_name)
        Gitlab::Template::GitlabCiYmlTemplate.find(template_name.chomp('.gitlab-ci.yml'))&.full_name
      end

      private

      def template_to_event_name(template)
        ActiveSupport::Inflector.parameterize(template.chomp('.gitlab-ci.yml'), separator: '_').underscore
      end
    end
  end
end
