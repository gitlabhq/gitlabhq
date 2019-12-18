# frozen_string_literal: true

require 'securerandom'

module QA
  module Resource
    class ProtectedBranch < Base
      attr_accessor :branch_name, :allowed_to_push, :allowed_to_merge, :protected

      attribute :project do
        Project.fabricate_via_api! do |resource|
          resource.name = 'protected-branch-project'
          resource.initialize_with_readme = true
        end
      end

      attribute :branch do
        Repository::ProjectPush.fabricate! do |project_push|
          project_push.project = project
          project_push.file_name = "new_file-#{SecureRandom.hex(8)}.md"
          project_push.commit_message = 'Add new file'
          project_push.branch_name = branch_name
          project_push.new_branch = true
          project_push.remote_branch = @branch_name
        end
      end

      def initialize
        @branch_name = 'test/branch'
        @allowed_to_push = {
          roles: Resource::ProtectedBranch::Roles::DEVS_AND_MAINTAINERS
        }
        @allowed_to_merge = {
          roles: Resource::ProtectedBranch::Roles::DEVS_AND_MAINTAINERS
        }
        @protected = false
      end

      def fabricate!
        populate(:branch)

        project.wait_for_push_new_branch @branch_name

        project.visit!
        Page::Project::Menu.perform(&:go_to_repository_settings)

        Page::Project::Settings::Repository.perform do |setting|
          setting.expand_protected_branches do |page|
            page.select_branch(branch_name)
            page.select_allowed_to_merge(allowed_to_merge)
            page.select_allowed_to_push(allowed_to_push)

            page.wait(reload: false) do
              !page.first('.btn-success').disabled?
            end

            page.protect_branch
          end
        end
      end

      def self.unprotect_via_api!(&block)
        self.remove_via_api!(&block)
      end

      def api_get_path
        "/projects/#{@project.api_resource[:id]}/protected_branches/#{@branch_name}"
      end

      def api_delete_path
        "/projects/#{@project.api_resource[:id]}/protected_branches/#{@branch_name}"
      end

      class Roles
        NO_ONE = 'No one'
        DEVS_AND_MAINTAINERS = 'Developers + Maintainers'
        MAINTAINERS = 'Maintainers'
      end
    end
  end
end
