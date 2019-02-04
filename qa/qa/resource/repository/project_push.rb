# frozen_string_literal: true

module QA
  module Resource
    module Repository
      class ProjectPush < Repository::Push
        attribute :project do
          Project.fabricate! do |resource|
            resource.name = 'project-with-code'
            resource.description = 'Project with repository'
          end
        end

        def initialize
          @file_name = 'file.txt'
          @file_content = '# This is test project'
          @commit_message = "This is a test commit"
          @branch_name = 'master'
          @new_branch = true
        end

        def repository_http_uri
          @repository_http_uri ||= project.repository_http_location.uri
        end

        def repository_ssh_uri
          @repository_ssh_uri ||= project.repository_ssh_location.uri
        end

        def fabricate!
          super
          project.visit!
        end
      end
    end
  end
end
