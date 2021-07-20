# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class DefaultBranch < Page::Base
          include Page::Component::Select2

          view 'app/views/projects/default_branch/_show.html.haml' do
            element :save_changes_button
            element :default_branch_dropdown
          end

          def set_default_branch(branch)
            find('.select2-chosen').click
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
