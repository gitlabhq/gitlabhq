# frozen_string_literal: true

module QA
  module Page
    module Project
      module Branches
        class Show < Page::Base
          view 'app/assets/javascripts/branches/components/delete_branch_button.vue' do
            element :delete_branch_button
          end

          view 'app/assets/javascripts/branches/components/delete_branch_modal.vue' do
            element :delete_branch_confirmation_button
          end

          view 'app/views/projects/branches/_branch.html.haml' do
            element :badge_content
            element :branch_container
            element :branch_link
          end

          view 'app/views/projects/branches/_panel.html.haml' do
            element :all_branches_container
          end

          view 'app/assets/javascripts/branches/components/delete_merged_branches.vue' do
            element :delete_merged_branches_dropdown_button
            element :delete_merged_branches_button
            element :delete_merged_branches_input
            element :delete_merged_branches_confirmation_button
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

          def has_branch_with_badge?(branch_name, badge)
            within_element(:branch_container, name: branch_name) do
              has_element?(:badge_content, text: badge)
            end
          end

          def delete_merged_branches(branches_length)
            click_element(:delete_merged_branches_dropdown_button)
            click_element(:delete_merged_branches_button)
            fill_element(:delete_merged_branches_input, branches_length)
            click_element(:delete_merged_branches_confirmation_button)
            finished_loading?
          end
        end
      end
    end
  end
end
