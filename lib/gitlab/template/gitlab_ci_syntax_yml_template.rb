# frozen_string_literal: true

module Gitlab
  module Template
    class GitlabCiSyntaxYmlTemplate < BaseTemplate
      class << self
        def extension
          '.gitlab-ci.yml'
        end

        def categories
          {
            'General' => ''
          }
        end

        def base_dir
          Rails.root.join('lib/gitlab/ci/syntax_templates')
        end

        def finder(project = nil)
          Gitlab::Template::Finders::GlobalTemplateFinder.new(
            self.base_dir, self.extension, self.categories
          )
        end
      end
    end
  end
end
