# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Overview
        module Groups
          class Index < QA::Page::Base
            view 'app/views/admin/groups/index.html.haml' do
              element :group_search_field, required: true
            end

            view 'app/views/admin/groups/_group.html.haml' do
              element :group_row_content
              element :group_name_link
            end

            def search_group(group_name)
              find_element(:group_search_field).set(group_name).send_keys(:return)
            end

            def click_group(group_name)
              within_element(:group_row_content, text: group_name) do
                click_element(:group_name_link)
              end
            end
          end
        end
      end
    end
  end
end
