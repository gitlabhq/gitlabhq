module Gitlab
  module Template
    class CustomLicenseTemplate < CustomTemplate
      class << self
        def extension
          '.txt'
        end

        def base_dir
          'LICENSE/'
        end
      end
    end
  end
end
