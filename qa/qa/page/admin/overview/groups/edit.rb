# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Overview
        module Groups
          class Edit < QA::Page::Base
            view 'app/views/admin/groups/_form.html.haml' do
              element :save_changes_button, required: true
            end

            def click_save_changes_button
              click_element :save_changes_button, Groups::Show
            end
          end
        end
      end
    end
  end
end

QA::Page::Admin::Overview::Groups::Edit.prepend_mod_with('Page::Admin::Overview::Groups::Edit', namespace: QA)
