# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class DefaultBranch < Page::Base
          include ::QA::Page::Component::Dropdown

          view 'app/views/projects/branch_defaults/_show.html.haml' do
            element :save_changes_button
          end

          view 'app/assets/javascripts/projects/settings/components/default_branch_selector.vue' do
            element :default_branch_dropdown
          end

          def set_default_branch(branch)
            expand_select_list
            search_and_select(branch)
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
