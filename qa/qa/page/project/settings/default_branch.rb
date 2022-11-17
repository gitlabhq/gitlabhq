# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class DefaultBranch < Page::Base
          view 'app/views/projects/branch_defaults/_show.html.haml' do
            element :save_changes_button
          end

          view 'app/assets/javascripts/projects/settings/components/default_branch_selector.vue' do
            element :default_branch_dropdown
          end

          view 'app/assets/javascripts/ref/components/ref_selector.vue' do
            element :ref_selector_searchbox
          end

          def set_default_branch(branch)
            find_element(:default_branch_dropdown, visible: false).click
            find_element(:ref_selector_searchbox, visible: false).fill_in(with: branch)
            click_button branch
          end

          def click_save_changes_button
            find('.btn-confirm').click
          end
        end
      end
    end
  end
end

QA::Page::Project::Settings::DefaultBranch.prepend_mod_with('Page::Project::Settings::DefaultBranch', namespace: QA)
