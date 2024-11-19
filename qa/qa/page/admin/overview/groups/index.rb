# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Overview
        module Groups
          class Index < QA::Page::Base
            view 'app/assets/javascripts/admin/groups/components/filtered_search_and_sort.vue' do
              element 'admin-groups-filtered-search-and-sort', required: true
            end

            view 'app/views/admin/groups/_group.html.haml' do
              element 'group-row-content'
              element 'group-name-link'
            end

            def search_group(group_name)
              within_element('admin-groups-filtered-search-and-sort') do
                find_element('filtered-search-term-input').set(group_name).send_keys(:return)
              end
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
