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
      p_ci_templates_implicit_jobs_dast_default_branch_deploy
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
