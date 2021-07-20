# frozen_string_literal: true

module Gitlab
  module Template
    class GitlabCiYmlTemplate < BaseTemplate
      BASE_EXCLUDED_PATTERNS = [%r{\.latest\.}].freeze

      TEMPLATES_WITH_LATEST_VERSION = {
        'Jobs/Browser-Performance-Testing' => true,
        'Security/API-Fuzzing' => true,
        'Security/DAST' => true,
        'Terraform' => true
      }.freeze

      def description
        "# This file is a template, and might need editing before it works on your project."
      end

      class << self
        extend ::Gitlab::Utils::Override
        include Gitlab::Utils::StrongMemoize

        def extension
          '.gitlab-ci.yml'
        end

        def categories
          {
            'General' => '',
            'Pages' => 'Pages',
            'Verify' => 'Verify',
            'Auto deploy' => 'autodeploy'
          }
        end

        def include_categories_for_file
          {
            "SAST#{self.extension}" => { 'Security' => 'Security' }
          }
        end

        def excluded_patterns
          strong_memoize(:excluded_patterns) do
            BASE_EXCLUDED_PATTERNS + additional_excluded_patterns
          end
        end

        def additional_excluded_patterns
          [%r{Verify/Browser-Performance}]
        end

        def base_dir
          Rails.root.join('lib/gitlab/ci/templates')
        end

        def finder(project = nil)
          Gitlab::Template::Finders::GlobalTemplateFinder.new(
            self.base_dir,
            self.extension,
            self.categories,
            self.include_categories_for_file,
            excluded_patterns: self.excluded_patterns
          )
        end

        override :find
        def find(key, project = nil)
          if try_redirect_to_latest?(key, project)
            key += '.latest'
          end

          super(key, project)
        end

        private

        # To gauge the impact of the latest template,
        # you can redirect the stable template to the latest template by enabling the feature flag.
        # See https://docs.gitlab.com/ee/development/cicd/templates.html#versioning for more information.
        def try_redirect_to_latest?(key, project)
          return false unless templates_with_latest_version[key]

          flag_name = "redirect_to_latest_template_#{key.underscore.tr('/', '_')}"
          ::Feature.enabled?(flag_name, project, default_enabled: :yaml)
        end

        def templates_with_latest_version
          TEMPLATES_WITH_LATEST_VERSION
        end
      end
    end
  end
end

Gitlab::Template::GitlabCiYmlTemplate.prepend_mod
