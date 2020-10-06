# frozen_string_literal: true

module Gitlab
  module Template
    class GitlabCiYmlTemplate < BaseTemplate
      BASE_EXCLUDED_PATTERNS = [%r{\.latest\.}].freeze

      def content
        explanation = "# This file is a template, and might need editing before it works on your project."
        [explanation, super].join("\n")
      end

      class << self
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
            self.base_dir, self.extension, self.categories, excluded_patterns: self.excluded_patterns
          )
        end
      end
    end
  end
end

Gitlab::Template::GitlabCiYmlTemplate.prepend_if_ee('::EE::Gitlab::Template::GitlabCiYmlTemplate')
