# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class ProtectedBranches < Page::Base
          view 'app/views/protected_branches/shared/_dropdown.html.haml' do
            element :protected_branch_dropdown
            element :protected_branch_dropdown_content
          end

          view 'app/views/protected_branches/_create_protected_branch.html.haml' do
            element :allowed_to_push_dropdown
            element :allowed_to_push_dropdown_content
            element :allowed_to_merge_dropdown
            element :allowed_to_merge_dropdown_content
          end

          view 'app/views/protected_branches/shared/_create_protected_branch.html.haml' do
            element :protect_button
          end

          def select_branch(branch_name)
            click_element :protected_branch_dropdown

            within_element(:protected_branch_dropdown_content) do
              click_on branch_name
            end
          end

          def select_allowed_to_merge(allowed)
            select_allowed(:merge, allowed)
          end

          def select_allowed_to_push(allowed)
            select_allowed(:push, allowed)
          end

          def protect_branch
            click_element(:protect_button, wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)
            wait_for_requests
          end

          private

          def select_allowed(action, allowed)
            click_element :"allowed_to_#{action}_dropdown"

            allowed[:roles] = Resource::ProtectedBranch::Roles::NO_ONE unless allowed.key?(:roles)

            within_element(:"allowed_to_#{action}_dropdown_content") do
              click_on allowed[:roles][:description]
              allowed[:users].each { |user| select_name user.username } if allowed.key?(:users)
              allowed[:groups].each { |group| select_name group.name } if allowed.key?(:groups)
            end
          end

          def select_name(name)
            fill_element(:dropdown_input_field, name)
            click_on name
          end
        end
      end
    end
  end
end

QA::Page::Project::Settings::ProtectedBranches.prepend_mod_with('Page::Project::Settings::ProtectedBranches', namespace: QA)
