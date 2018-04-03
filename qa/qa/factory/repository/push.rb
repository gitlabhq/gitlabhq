module QA
  module Factory
    module Repository
      class Push < Factory::Base
        attr_writer :file_name, :file_content, :commit_message, :branch_name, :new_branch

        dependency Factory::Resource::Project, as: :project do |project|
          project.name = 'project-with-code'
          project.description = 'Project with repository'
        end

        def initialize
          @file_name = 'file.txt'
          @file_content = '# This is test project'
          @commit_message = "Add #{@file_name}"
          @branch_name = 'master'
          @new_branch = true
        end

        def fabricate!
          project.visit!

          Git::Repository.perform do |repository|
            repository.location = Page::Project::Show.act do
              choose_repository_clone_http
              repository_location
            end

            repository.use_default_credentials
            repository.clone
            repository.configure_identity('GitLab QA', 'root@gitlab.com')

            if @new_branch
              repository.checkout_new_branch(@branch_name)
            else
              repository.checkout(@branch_name)
            end

            repository.add_file(@file_name, @file_content)
            repository.commit(@commit_message)
            repository.push_changes(@branch_name)
          end
        end
      end
    end
  end
end
