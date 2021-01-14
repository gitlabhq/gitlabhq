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
      end
    end
  end
end
