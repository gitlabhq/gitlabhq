# frozen_string_literal: true

module Security
  module CiConfiguration
    class BaseBuildAction
      def initialize(auto_devops_enabled, existing_gitlab_ci_content)
        @auto_devops_enabled = auto_devops_enabled
        @existing_gitlab_ci_content = existing_gitlab_ci_content || {}
      end

      def generate
        action = @existing_gitlab_ci_content.present? ? 'update' : 'create'

        update_existing_content!

        { action: action, file_path: '.gitlab-ci.yml', content: prepare_existing_content, default_values_overwritten: @default_values_overwritten }
      end

      private

      def generate_includes
        includes = @existing_gitlab_ci_content['include'] || []
        includes = Array.wrap(includes)
        includes << { 'template' => template }
        includes.uniq
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
          # Secret Detection customization: https://docs.gitlab.com/ee/user/application_security/secret_detection/#customizing-settings
          # Dependency Scanning customization: https://docs.gitlab.com/ee/user/application_security/dependency_scanning/#customizing-the-dependency-scanning-settings
          # Note that environment variables can be set in several places
          # See https://docs.gitlab.com/ee/ci/variables/#cicd-variable-precedence
        YAML
      end
    end
  end
end
