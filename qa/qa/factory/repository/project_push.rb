module QA
  module Factory
    module Repository
      class ProjectPush < Factory::Repository::Push
        dependency Factory::Resource::Project, as: :project do |project|
          project.name = 'project-with-code'
          project.description = 'Project with repository'
        end

        product :output do |factory|
          factory.output
        end

        product :project do |factory|
          factory.project
        end

        def initialize
          @file_name = 'file.txt'
          @file_content = '# This is test project'
          @commit_message = "This is a test commit"
          @branch_name = 'master'
          @new_branch = true
        end

        def repository_http_uri
          @repository_http_uri ||= begin
            project.visit!
            Page::Project::Show.act do
              choose_repository_clone_http
              repository_location.uri
            end
          end
        end

        def repository_ssh_uri
          @repository_ssh_uri ||= begin
            project.visit!
            Page::Project::Show.act do
              choose_repository_clone_ssh
              repository_location.uri
            end
          end
        end
      end
    end
  end
end
