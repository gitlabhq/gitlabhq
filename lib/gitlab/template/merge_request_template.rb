# frozen_string_literal: true

module Gitlab
  module Template
    class MergeRequestTemplate < BaseTemplate
      class << self
        def extension
          '.md'
        end

        def base_dir
          '.gitlab/merge_request_templates/'
        end

        def finder(project)
          Gitlab::Template::Finders::RepoTemplateFinder.new(project, self.base_dir, self.extension, self.categories)
        end

        def by_category(category, project = nil, empty_category_title: nil)
          super(category, project, empty_category_title: _('Project Templates'))
        end
      end
    end
  end
end
