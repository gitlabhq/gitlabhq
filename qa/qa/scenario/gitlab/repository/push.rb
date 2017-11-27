require "pry-byebug"

module QA
  module Scenario
    module Gitlab
      module Repository
        class Push < Scenario::Template
          attr_writer :file_name,
                      :file_content,
                      :commit_message,
                      :branch_name

          def initialize
            @file_name = 'file.txt'
            @file_content = '# This is test project'
            @commit_message = "Add #{@file_name}"
            @branch_name = 'master'
          end

          def perform
            Git::Repository.perform do |repository|
              repository.location = Page::Project::Show.act do
                choose_repository_clone_http
                repository_location
              end

              repository.use_default_credentials
              repository.clone
              repository.configure_identity('GitLab QA', 'root@gitlab.com')

              repository.add_file(@file_name, @file_content)
              repository.commit(@commit_message)
              repository.push_changes(@branch_name)
            end
          end
        end
      end
    end
  end
end
