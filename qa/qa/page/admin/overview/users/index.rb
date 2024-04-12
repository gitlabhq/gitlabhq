# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Overview
        module Users
          class Index < QA::Page::Base
            view 'app/views/admin/users/_users.html.haml' do
              element 'user-search-field'
              element 'pending-approval-tab'
            end

            view 'app/assets/javascripts/vue_shared/components/users_table/users_table.vue' do
              element 'user-row-content'
            end

            def search_user(username)
              find_element('user-search-field').set(username).send_keys(:return)
            end

            def click_pending_approval_tab
              click_element 'pending-approval-tab'
            end

            def click_user(username)
              within_element('user-row-content', text: username) do
                click_link(username)
              end
            end

            def has_username?(username)
              has_element?('user-row-content', text: username, wait: 1)
            end
          end
        end
      end
    end
  end
end
