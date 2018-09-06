module Gitlab
  module Template
    class CustomDockerfileTemplate < CustomTemplate
      class << self
        def extension
          '.dockerfile'
        end

        def base_dir
          'Dockerfile/'
        end
      end
    end
  end
end
