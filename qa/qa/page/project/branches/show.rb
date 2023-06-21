# frozen_string_literal: true

module QA
  module Page
    module Project
      module Branches
        class Show < Page::Base
          view 'app/assets/javascripts/branches/components/branch_more_actions.vue' do
            element :delete_branch_button
          end

          view 'app/assets/javascripts/branches/components/delete_branch_modal.vue' do
            element :delete_branch_confirmation_button
          end

          view 'app/views/projects/branches/_branch.html.haml' do
            element :branch_container
            element :branch_link
          end

          view 'app/views/projects/branches/_panel.html.haml' do
            element :all_branches_container
          end

          def delete_branch(branch_name)
            within_element(:branch_container, name: branch_name) do
              click_element(:delete_branch_button)
            end

            click_element(:delete_branch_confirmation_button)

            finished_loading?
          end

          def has_no_branch?(branch_name, reload: false)
            wait_until(reload: reload) do
              within_element(:all_branches_container) do
                has_no_element?(:branch_link, text: branch_name)
              end
            end
          end
        end
      end
    end
  end
end
