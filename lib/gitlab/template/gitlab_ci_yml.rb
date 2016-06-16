module Gitlab
  module Template
    class GitlabCIYml < BaseTemplate
      class << self
        def extension
          '.gitlab-ci.yml'
        end

        def categories
          {
            "General" => '',
            "Pages" => 'Pages'
          }
        end

        def base_dir
          Rails.root.join('vendor/gitlab-ci-yml')
        end
      end
    end
  end
end
