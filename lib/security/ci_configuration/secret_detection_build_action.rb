# frozen_string_literal: true

module Security
  module CiConfiguration
    class SecretDetectionBuildAction < BaseBuildAction
      def initialize(
        auto_devops_enabled, params, existing_gitlab_ci_content,
        ci_config_path = ::Ci::Pipeline::DEFAULT_CONFIG_PATH)
        super(auto_devops_enabled, existing_gitlab_ci_content, ci_config_path)
        @params = params || {}
        @variables = @params[:initialize_with_secret_detection] ? { 'SECRET_DETECTION_ENABLED' => 'true' } : {}
        @default_values_overwritten = false
      end

      private

      def update_existing_content!
        add_stages!([Security::CiConfiguration::DEFAULT_TEST_STAGE]) unless @auto_devops_enabled
        @existing_gitlab_ci_content['stages'] = set_stages
        @existing_gitlab_ci_content['variables'] = set_variables(global_variables, @existing_gitlab_ci_content)
        @existing_gitlab_ci_content['secret_detection'] = set_secret_detection_block
        @existing_gitlab_ci_content['include'] = generate_includes

        # Remove any empty sections to keep the config clean
        @existing_gitlab_ci_content.select! { |_k, v| v.present? }
        @existing_gitlab_ci_content['secret_detection']&.select! { |_k, v| v.present? }
      end

      def set_stages
        existing_stages = @existing_gitlab_ci_content['stages'] || []
        base_stages = @auto_devops_enabled ? auto_devops_stages : ['test']
        (existing_stages + base_stages + [secret_detection_stage]).uniq
      end

      def auto_devops_stages
        auto_devops_template = YAML.safe_load(Gitlab::Template::GitlabCiYmlTemplate.find('Auto-DevOps').content)
        auto_devops_template['stages']
      rescue StandardError => e
        Gitlab::AppLogger.error("Failed to process Auto-DevOps template: #{e.message}")
        %w[build test deploy]
      end

      def set_variables(variables, hash_to_update = {})
        hash_to_update['variables'] ||= {}

        variables.each do |key|
          if @variables[key].present?
            hash_to_update['variables'][key] = @variables[key]
            @default_values_overwritten = true
          end
        end

        hash_to_update['variables']
      end

      def set_secret_detection_block
        secret_detection_content = @existing_gitlab_ci_content['secret_detection'] || {}
        secret_detection_content['variables'] = set_variables(secret_detection_variables)
        secret_detection_content['stage'] = secret_detection_stage
        secret_detection_content.select { |_k, v| v.present? }
      end

      def secret_detection_stage
        'secret-detection'
      end

      def template
        return 'Auto-DevOps.gitlab-ci.yml' if @auto_devops_enabled

        'Security/Secret-Detection.gitlab-ci.yml'
      end

      def global_variables
        %w[
          SECRET_DETECTION_ENABLED
          SECURE_ANALYZERS_PREFIX
        ]
      end

      def secret_detection_variables
        %w[
          SECRET_DETECTION_HISTORIC_SCAN
          SECRET_DETECTION_IMAGE_SUFFIX
          SECRET_DETECTION_EXCLUDED_PATHS
        ]
      end
    end
  end
end
