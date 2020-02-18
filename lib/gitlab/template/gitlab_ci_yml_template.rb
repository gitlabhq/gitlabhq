# frozen_string_literal: true

module Gitlab
  module Template
    class GitlabCiYmlTemplate < BaseTemplate
      def content
        explanation = "# This file is a template, and might need editing before it works on your project."
        [explanation, super].join("\n")
      end

      class << self
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

        def disabled_templates
          %w[
            Verify/Browser-Performance
          ]
        end

        def base_dir
          Rails.root.join('lib/gitlab/ci/templates')
        end

        def finder(project = nil)
          Gitlab::Template::Finders::GlobalTemplateFinder.new(
            self.base_dir, self.extension, self.categories, exclusions: self.disabled_templates
          )
        end
      end
    end
  end
end

Gitlab::Template::GitlabCiYmlTemplate.prepend_if_ee('::EE::Gitlab::Template::GitlabCiYmlTemplate')
