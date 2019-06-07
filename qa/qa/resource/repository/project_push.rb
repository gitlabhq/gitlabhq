# frozen_string_literal: true

module QA
  module Resource
    module Repository
      class ProjectPush < Repository::Push
        attr_writer :wait_for_push

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
          @wait_for_push = true
        end

        def repository_http_uri
          @repository_http_uri ||= project.repository_http_location.uri
        end

        def repository_ssh_uri
          @repository_ssh_uri ||= project.repository_ssh_location.uri
        end

        def fabricate!
          super
          project.wait_for_push @commit_message if @wait_for_push
          project.visit!
        end
      end
    end
  end
end
