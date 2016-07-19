module Gitlab
  module Template
    class Gitignore < BaseTemplate
      class << self
        def extension
          '.gitignore'
        end

        def categories
          {
            "Languages" => '',
            "Global"    => 'Global'
          }
        end

        def base_dir
          Rails.root.join('vendor/gitignore')
        end
      end
    end
  end
end
