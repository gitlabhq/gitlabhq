# frozen_string_literal: true

module QA
  module Resource
    class ProtectedBranch < Base
      attr_accessor :branch_name, :allow_to_push, :allow_to_merge, :protected

      attribute :project do
        Project.fabricate_via_api! do |resource|
          resource.name = 'protected-branch-project'
          resource.initialize_with_readme = true
        end
      end

      attribute :branch do
        Repository::ProjectPush.fabricate! do |project_push|
          project_push.project = project
          project_push.file_name = 'new_file.md'
          project_push.commit_message = 'Add new file'
          project_push.branch_name = branch_name
          project_push.new_branch = true
          project_push.remote_branch = @branch_name
        end
      end

      def initialize
        @branch_name = 'test/branch'
        @allow_to_push = true
        @allow_to_merge = true
        @protected = false
      end

      def fabricate!
        populate(:branch)

        project.wait_for_push_new_branch @branch_name

        # The upcoming process will make it access the Protected Branches page,
        # select the already created branch and protect it according
        # to `allow_to_push` variable.
        return branch unless @protected

        project.visit!
        Page::Project::Menu.perform(&:go_to_repository_settings)

        Page::Project::Settings::Repository.perform do |setting|
          setting.expand_protected_branches do |page|
            page.select_branch(branch_name)

            if allow_to_push
              page.allow_devs_and_maintainers_to_push
            else
              page.allow_no_one_to_push
            end

            if allow_to_merge
              page.allow_devs_and_maintainers_to_merge
            else
              page.allow_no_one_to_merge
            end

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
    end
  end
end
