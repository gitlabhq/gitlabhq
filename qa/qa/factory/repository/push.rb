module QA
  module Factory
    module Repository
      class Push < Factory::Base
        attr_accessor :file_name, :file_content, :commit_message,
                      :branch_name, :new_branch

        attr_writer :remote_branch

        dependency Factory::Resource::Project, as: :project do |project|
          project.name = 'project-with-code'
          project.description = 'Project with repository'
        end

        def initialize
          @file_name = 'file.txt'
          @file_content = '# This is test project'
          @commit_message = "This is a test commit"
          @branch_name = 'master'
          @new_branch = true
        end

        def remote_branch
          @remote_branch ||= branch_name
        end

        def directory=(dir)
          raise "Must set directory as a Pathname" unless dir.is_a?(Pathname)

          @directory = dir
        end

        def fabricate!
          project.visit!

          Git::Repository.perform do |repository|
            repository.uri = Page::Project::Show.act do
              choose_repository_clone_http
              repository_location.uri
            end

            repository.use_default_credentials
            repository.clone
            repository.configure_identity('GitLab QA', 'root@gitlab.com')

            if new_branch
              repository.checkout_new_branch(branch_name)
            else
              repository.checkout(branch_name)
            end

            if @directory
              @directory.each_child do |f|
                repository.add_file(f.basename, f.read) if f.file?
              end
            else
              repository.add_file(file_name, file_content)
            end

            repository.commit(commit_message)
            repository.push_changes("#{branch_name}:#{remote_branch}")
          end
        end
      end
    end
  end
end
