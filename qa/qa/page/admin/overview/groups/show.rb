# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Overview
        module Groups
          class Show < QA::Page::Base
            view 'app/views/admin/groups/show.html.haml' do
              element 'edit-group-link', required: true
            end

            def click_edit_group_link
              click_element 'edit-group-link', Groups::Edit
            end
          end
        end
      end
    end
  end
end
