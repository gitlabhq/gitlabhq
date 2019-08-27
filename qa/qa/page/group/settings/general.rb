# frozen_string_literal: true

module QA
  module Page
    module Group
      module Settings
        class General < QA::Page::Base
          view 'app/views/groups/edit.html.haml' do
            element :permission_lfs_2fa_section
          end
          view 'app/views/groups/settings/_permissions.html.haml' do
            element :save_permissions_changes_button
          end
        end
      end
    end
  end
end
