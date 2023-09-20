# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Overview
        module Groups
          class Index < QA::Page::Base
            view 'app/views/admin/groups/index.html.haml' do
              element 'group-search-field', required: true
            end

            view 'app/views/admin/groups/_group.html.haml' do
              element 'group-row-content'
              element 'group-name-link'
            end

            def search_group(group_name)
              find_element('group-search-field').set(group_name).send_keys(:return)
            end

            def click_group(group_name)
              within_element('group-row-content', text: group_name) do
                click_element('group-name-link')
              end
            end
          end
        end
      end
    end
  end
end
