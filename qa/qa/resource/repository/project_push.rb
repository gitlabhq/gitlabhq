# frozen_string_literal: true

require 'securerandom'

module QA
  module Resource
    module Repository
      class ProjectPush < Repository::Push
        attr_accessor :project_name
        attr_writer :wait_for_push

        attribute :project do
          Project.fabricate! do |resource|
            resource.name = project_name
            resource.description = 'Project with repository'
          end
        end

        def initialize
          @file_name = "file-#{SecureRandom.hex(8)}.txt"
          @file_content = '# This is test project'
          @commit_message = "This is a test commit"
          @branch_name = 'master'
          @new_branch = true
          @project_name = 'project-with-code'
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
        end
      end
    end
  end
end
