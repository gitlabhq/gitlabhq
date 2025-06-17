# frozen_string_literal: true

module Security
  module CiConfiguration
    DEFAULT_TEST_STAGE = 'test'

    class BaseBuildAction
      def initialize(auto_devops_enabled, existing_gitlab_ci_content, ci_config_path = ::Ci::Pipeline::DEFAULT_CONFIG_PATH)
        @auto_devops_enabled = auto_devops_enabled
        @existing_gitlab_ci_content = existing_gitlab_ci_content || {}
        @ci_config_path = ci_config_path.presence || ::Ci::Pipeline::DEFAULT_CONFIG_PATH
      end

      def generate
        action = @existing_gitlab_ci_content.present? ? 'update' : 'create'

        update_existing_content!

        { action: action, file_path: @ci_config_path, content: prepare_existing_content, default_values_overwritten: @default_values_overwritten }
      end

      private

      def generate_includes
        includes = @existing_gitlab_ci_content['include'] || []
        includes = Array.wrap(includes)
        includes << { 'template' => template }
        includes.uniq
      end

      def add_stages!(stages)
        existing_stages = @existing_gitlab_ci_content['stages'] || []
        @existing_gitlab_ci_content['stages'] = (existing_stages + stages).uniq
      end

      def auto_devops_stages
        auto_devops_template = YAML.safe_load(Gitlab::Template::GitlabCiYmlTemplate.find('Auto-DevOps').content)
        auto_devops_template['stages']
      end

      def prepare_existing_content
        content = @existing_gitlab_ci_content.to_yaml
        content = remove_document_delimiter(content)

        content.prepend(comment)
      end

      def remove_document_delimiter(content)
        content.gsub(/^---\n/, '')
      end

      def comment
        <<~YAML
          # You can override the included template(s) by including variable overrides
          # SAST customization: https://docs.gitlab.com/ee/user/application_security/sast/#customizing-the-sast-settings
          # Secret Detection customization: https://docs.gitlab.com/user/application_security/secret_detection/pipeline/configure
          # Dependency Scanning customization: https://docs.gitlab.com/ee/user/application_security/dependency_scanning/#customizing-the-dependency-scanning-settings
          # Container Scanning customization: https://docs.gitlab.com/ee/user/application_security/container_scanning/#customizing-the-container-scanning-settings
          # Note that environment variables can be set in several places
          # See https://docs.gitlab.com/ee/ci/variables/#cicd-variable-precedence
        YAML
      end
    end
  end
end
