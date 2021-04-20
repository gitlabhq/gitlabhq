# frozen_string_literal: true

module Gitlab::UsageDataCounters
  class CiTemplateUniqueCounter
    REDIS_SLOT = 'ci_templates'

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
        if event = unique_project_event(template, config_source)
          Gitlab::UsageDataCounters::HLLRedisCounter.track_event(event, values: project_id)
        end
      end

      private

      def unique_project_event(template, config_source)
        if name = TEMPLATE_TO_EVENT[template]
          prefix = 'implicit_' if config_source.to_s == 'auto_devops_source'

          "p_#{REDIS_SLOT}_#{prefix}#{name}"
        end
      end
    end
  end
end
