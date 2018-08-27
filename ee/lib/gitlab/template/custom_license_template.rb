module Gitlab
  module Template
    class CustomLicenseTemplate < BaseTemplate
      class << self
        def extension
          '.txt'
        end

        def base_dir
          'LICENSE/'
        end

        def finder(project)
          Gitlab::Template::Finders::RepoTemplateFinder.new(project, self.base_dir, self.extension, self.categories)
        end
      end
    end
  end
end
