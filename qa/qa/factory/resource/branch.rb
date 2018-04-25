module QA
  module Factory
    module Resource
      class Branch < Factory::Base
        attr_accessor :project, :branch_name,
                      :allow_to_push, :allow_to_merge, :protected

        dependency Factory::Resource::Project, as: :project do |project|
          project.name = 'protected-branch-project'
        end

        product :name do
          Page::Project::Settings::Repository.act do
            expand_protected_branches(&:last_branch_name)
          end
        end

        product :push_allowance do
          Page::Project::Settings::Repository.act do
            expand_protected_branches(&:last_push_allowance)
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

          Factory::Repository::Push.fabricate! do |resource|
            resource.project = project
            resource.file_name = 'kick-off.txt'
            resource.commit_message = 'First commit'
          end

          branch = Factory::Repository::Push.fabricate! do |resource|
            resource.project = project
            resource.file_name = 'README.md'
            resource.commit_message = 'Add readme'
            resource.branch_name = "master:#{@branch_name}"
          end

          Page::Project::Show.act { wait_for_push }

          # The upcoming process will make it access the Protected Branches page,
          # select the already created branch and protect it according
          # to `allow_to_push` variable.
          return branch unless @protected

          Page::Menu::Side.act do
            click_repository_settings
          end

          Page::Project::Settings::Repository.perform do |setting|
            setting.expand_protected_branches do |page|
              page.select_branch(branch_name)

              if allow_to_push
                page.allow_devs_and_masters_to_push
              else
                page.allow_no_one_to_push
              end

              if allow_to_merge
                page.allow_devs_and_masters_to_merge
              else
                page.allow_no_one_to_merge
              end

              page.wait(reload: false) do
                !page.first('.btn-create').disabled?
              end

              page.protect_branch
            end
          end
        end
      end
    end
  end
end
