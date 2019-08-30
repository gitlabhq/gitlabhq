# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class ProtectedBranches < Page::Base
          view 'app/views/projects/protected_branches/shared/_dropdown.html.haml' do
            element :protected_branch_select
            element :protected_branch_dropdown
          end

          view 'app/views/projects/protected_branches/_create_protected_branch.html.haml' do
            element :allowed_to_push_select
            element :allowed_to_push_dropdown
            element :allowed_to_merge_select
            element :allowed_to_merge_dropdown
          end

          view 'app/views/projects/protected_branches/_update_protected_branch.html.haml' do
            element :allowed_to_merge
          end

          view 'app/views/projects/protected_branches/shared/_branches_list.html.haml' do
            element :protected_branches_list
          end

          def select_branch(branch_name)
            click_element :protected_branch_select

            within_element(:protected_branch_dropdown) do
              click_on branch_name
            end
          end

          def allow_no_one_to_push
            go_to_allow(:push, 'No one')
          end

          def allow_devs_and_maintainers_to_push
            go_to_allow(:push, 'Developers + Maintainers')
          end

          # @deprecated
          alias_method :allow_devs_and_masters_to_push, :allow_devs_and_maintainers_to_push

          def allow_no_one_to_merge
            go_to_allow(:merge, 'No one')
          end

          def allow_devs_and_maintainers_to_merge
            go_to_allow(:merge, 'Developers + Maintainers')
          end

          # @deprecated
          alias_method :allow_devs_and_masters_to_merge, :allow_devs_and_maintainers_to_merge

          def protect_branch
            click_on 'Protect'
          end

          private

          def go_to_allow(action, text)
            click_element :"allowed_to_#{action}_select"

            within_element(:"allowed_to_#{action}_dropdown") do
              click_on text
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::Settings::ProtectedBranches.prepend_if_ee('QA::EE::Page::Project::Settings::ProtectedBranches')
