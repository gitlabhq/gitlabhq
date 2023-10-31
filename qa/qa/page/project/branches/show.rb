# frozen_string_literal: true

module QA
  module Page
    module Project
      module Branches
        class Show < Page::Base
          view 'app/assets/javascripts/branches/components/branch_more_actions.vue' do
            element 'delete-branch-button'
          end

          view 'app/assets/javascripts/branches/components/delete_branch_modal.vue' do
            element 'delete-branch-confirmation-button'
          end

          view 'app/views/projects/branches/_branch.html.haml' do
            element 'branch-container'
            element 'branch-link'
          end

          view 'app/views/projects/branches/_panel.html.haml' do
            element 'all-branches-container'
          end

          def delete_branch(branch_name)
            within_element('branch-container', name: branch_name) do
              click_element('delete-branch-button')
            end

            click_element('delete-branch-confirmation-button')

            finished_loading?
          end

          def has_no_branch?(branch_name, reload: false)
            wait_until(reload: reload) do
              within_element('all-branches-container') do
                has_no_element?('branch-link', text: branch_name)
              end
            end
          end
        end
      end
    end
  end
end
