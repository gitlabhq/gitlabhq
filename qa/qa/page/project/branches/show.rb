# frozen_string_literal: true

module QA
  module Page
    module Project
      module Branches
        class Show < Page::Base
          view 'app/views/projects/branches/_branch.html.haml' do
            element :remove_btn
          end
          view 'app/views/projects/branches/_panel.html.haml' do
            element :all_branches
          end
          view 'app/views/projects/branches/index.html.haml' do
            element :delete_merged_branches
          end

          def delete_branch(branch_name)
            within_element(:all_branches) do
              within(".js-branch-#{branch_name}") do
                accept_alert do
                  click_element(:remove_btn)
                end
              end
            end

            finished_loading?
          end

          def has_branch_title?(branch_title)
            within_element(:all_branches) do
              within(".item-title") do
                has_text?(branch_title)
              end
            end
          end

          def has_branch_with_badge?(branch_name, badge)
            within_element(:all_branches) do
              within(".js-branch-#{branch_name} .badge") do
                has_text?(badge)
              end
            end
          end

          def delete_merged_branches
            accept_alert do
              click_element(:delete_merged_branches)
            end
          end

          def wait_for_texts_not_to_be_visible(texts)
            text_not_visible = wait do
              texts.all? do |text|
                has_no_text?(text)
              end
            end
            raise "Expected text(s) #{texts} not to be visible" unless text_not_visible
          end
        end
      end
    end
  end
end
