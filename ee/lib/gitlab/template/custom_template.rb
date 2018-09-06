module Gitlab
  module Template
    class CustomTemplate < BaseTemplate
      class << self
        def categories
          { 'Custom' => '' }
        end

        def finder(project)
          Gitlab::Template::Finders::RepoTemplateFinder.new(project, self.base_dir, self.extension, self.categories)
        end
      end
    end
  end
end
