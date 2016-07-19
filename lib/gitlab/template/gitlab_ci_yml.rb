module Gitlab
  module Template
    class GitlabCiYml < BaseTemplate
      def content
        explanation = "# This file is a template, and might need editing before it works on your project."
        [explanation, super].join("\n")
      end

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
