module Gitlab
  module Template
    class CustomGitlabCiYmlTemplate < CustomTemplate
      class << self
        def extension
          '.yml'
        end

        def base_dir
          'gitlab-ci/'
        end
      end
    end
  end
end
