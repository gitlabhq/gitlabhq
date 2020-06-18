# frozen_string_literal: true

require 'securerandom'

module QA
  module Resource
    class ProtectedBranch < Base
      attr_accessor :branch_name,
                    :allowed_to_push,
                    :allowed_to_merge,
                    :protected,
                    :new_branch,
                    :require_code_owner_approval

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
          project_push.remote_branch = branch_name
        end
      end

      def initialize
        @new_branch = true
        @branch_name = 'test/branch'
        @allowed_to_push = {
          roles: Resource::ProtectedBranch::Roles::DEVS_AND_MAINTAINERS
        }
        @allowed_to_merge = {
          roles: Resource::ProtectedBranch::Roles::DEVS_AND_MAINTAINERS
        }
        @protected = false
        @require_code_owner_approval = true
      end

      def fabricate!
        if new_branch
          populate(:branch)

          project.wait_for_push_new_branch branch_name
        end

        project.visit!
        Page::Project::Menu.perform(&:go_to_repository_settings)

        Page::Project::Settings::Repository.perform do |setting|
          setting.expand_protected_branches do |page|
            if new_branch
              page.select_branch(branch_name)
              page.select_allowed_to_merge(allowed_to_merge)
              page.select_allowed_to_push(allowed_to_push)
              page.protect_branch
            else
              page.require_code_owner_approval(branch_name) if require_code_owner_approval
            end
          end
        end
      end

      def self.unprotect_via_api!(&block)
        self.remove_via_api!(&block)
      end

      def api_get_path
        "/projects/#{project.id}/protected_branches/#{branch_name}"
      end

      def api_delete_path
        "/projects/#{project.id}/protected_branches/#{branch_name}"
      end

      class Roles
        NO_ONE = 'No one'
        DEVS_AND_MAINTAINERS = 'Developers + Maintainers'
        MAINTAINERS = 'Maintainers'
      end
    end
  end
end
