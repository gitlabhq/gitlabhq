# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Overview
        module Users
          class Index < QA::Page::Base
            view 'app/assets/javascripts/vue_shared/components/users_table/users_table.vue' do
              element 'user-row-content'
            end

            def search_user(username)
              submit_search_term(username)
            end

            def choose_pending_approval_filter
              select_tokens('state', '=', 'Pending approval', submit: true)
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
