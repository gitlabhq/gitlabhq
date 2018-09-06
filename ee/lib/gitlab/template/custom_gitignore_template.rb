module Gitlab
  module Template
    class CustomGitignoreTemplate < CustomTemplate
      class << self
        def extension
          '.gitignore'
        end

        def base_dir
          'gitignore/'
        end
      end
    end
  end
end
