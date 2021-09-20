# frozen_string_literal: true

module Gitlab::UsageDataCounters
  class CiTemplateUniqueCounter
    REDIS_SLOT = 'ci_templates'
    KNOWN_EVENTS_FILE_PATH = File.expand_path('known_events/ci_templates.yml', __dir__)

    # NOTE: Events originating from implicit Auto DevOps pipelines get prefixed with `implicit_`
    TEMPLATE_TO_EVENT = {
      '5-Minute-Production-App.gitlab-ci.yml' => '5_min_production_app',
      'Auto-DevOps.gitlab-ci.yml' => 'auto_devops',
      'AWS/CF-Provision-and-Deploy-EC2.gitlab-ci.yml' => 'aws_cf_deploy_ec2',
      'AWS/Deploy-ECS.gitlab-ci.yml' => 'aws_deploy_ecs',
      'Jobs/Build.gitlab-ci.yml' => 'auto_devops_build',
      'Jobs/Deploy.gitlab-ci.yml' => 'auto_devops_deploy',
      'Jobs/Deploy.latest.gitlab-ci.yml' => 'auto_devops_deploy_latest',
      'Security/SAST.gitlab-ci.yml' => 'security_sast',
      'Security/Secret-Detection.gitlab-ci.yml' => 'security_secret_detection',
      'Terraform/Base.latest.gitlab-ci.yml' => 'terraform_base_latest'
    }.freeze

    class << self
      def track_unique_project_event(project_id:, template:, config_source:)
        Gitlab::UsageDataCounters::HLLRedisCounter.track_event(ci_template_event_name(template, config_source), values: project_id)
      end

      def ci_templates(relative_base = 'lib/gitlab/ci/templates')
        Dir.glob('**/*.gitlab-ci.yml', base: Rails.root.join(relative_base))
      end

      def ci_template_event_name(template_name, config_source)
        prefix = 'implicit_' if config_source.to_s == 'auto_devops_source'
        template_event_name = TEMPLATE_TO_EVENT[template_name] || template_to_event_name(template_name)

        "p_#{REDIS_SLOT}_#{prefix}#{template_event_name}"
      end

      private

      def template_to_event_name(template)
        ActiveSupport::Inflector.parameterize(template.chomp('.gitlab-ci.yml'), separator: '_').underscore
      end
    end
  end
end
