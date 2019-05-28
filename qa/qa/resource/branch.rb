# frozen_string_literal: true

module QA
  module Resource
    class Branch < Base
      attr_accessor :project, :branch_name,
                    :allow_to_push, :allow_to_merge, :protected

      attribute :project do
        Project.fabricate! do |resource|
          resource.name = 'protected-branch-project'
        end
      end

      def initialize
        @branch_name = 'test/branch'
        @allow_to_push = true
        @allow_to_merge = true
        @protected = false
      end

      def fabricate!
        project.visit!

        Repository::ProjectPush.fabricate! do |resource|
          resource.project = project
          resource.file_name = 'kick-off.txt'
          resource.commit_message = 'First commit'
        end

        branch = Repository::ProjectPush.fabricate! do |resource|
          resource.project = project
          resource.file_name = 'README.md'
          resource.commit_message = 'Add readme'
          resource.branch_name = 'master'
          resource.new_branch = false
          resource.remote_branch = @branch_name
        end

        Page::Project::Show.perform do |page|
          page.wait { page.has_content?(branch_name) }
        end

        # The upcoming process will make it access the Protected Branches page,
        # select the already created branch and protect it according
        # to `allow_to_push` variable.
        return branch unless @protected

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
    end
  end
end
