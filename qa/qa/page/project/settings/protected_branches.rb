# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class ProtectedBranches < Page::Base
          include Page::Component::ListboxFilter

          view 'app/views/protected_branches/shared/_index.html.haml' do
            element 'add-protected-branch-button'
          end

          view 'app/views/protected_branches/shared/_dropdown.html.haml' do
            element 'protected-branch-dropdown'
            element 'protected-branch-dropdown-content'
          end

          view 'app/assets/javascripts/protected_branches/protected_branch_create.js' do
            element 'allowed-to-push-dropdown'
            element 'allowed-to-merge-dropdown'
          end

          view 'app/views/protected_branches/shared/_create_protected_branch.html.haml' do
            element 'protect-button'
          end

          def select_branch(branch_name)
            click_element('add-protected-branch-button')
            click_element('protected-branch-dropdown')

            within_element('protected-branch-dropdown-content') do
              click_on(branch_name)
            end
          end

          def select_allowed_to_merge(allowed)
            select_allowed(:merge, allowed)
          end

          def select_allowed_to_push(allowed)
            select_allowed(:push, allowed)
          end

          def protect_branch
            click_element('protect-button', wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)
            wait_for_requests
          end

          private

          def select_allowed(action, allowed)
            within_element("allowed-to-#{action}-dropdown") do
              click_element ".js-allowed-to-#{action}"
              allowed[:roles] = Resource::ProtectedBranch::Roles::NO_ONE unless allowed.key?(:roles)

              click_on allowed[:roles][:description]

              allowed[:users].each { |user| select_name user.username } if allowed.key?(:users)
              allowed[:groups].each { |group| select_name group.name } if allowed.key?(:groups)
            end
          end

          def select_name(name)
            fill_element('.gl-search-box-by-type-input', name)
            click_on name
          end
        end
      end
    end
  end
end

QA::Page::Project::Settings::ProtectedBranches.prepend_mod_with('Page::Project::Settings::ProtectedBranches', namespace: QA)
