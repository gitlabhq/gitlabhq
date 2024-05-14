# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Overview
        module Users
          class Index < QA::Page::Base
            view 'app/views/admin/users/_users.html.haml' do
              element 'filtered-search-block'
            end

            view 'app/assets/javascripts/vue_shared/components/users_table/users_table.vue' do
              element 'user-row-content'
            end

            # Depending on how we interact with the search, one of these two selectors will be present
            INPUT_SELECTORS = '[data-testid="filtered-search-term-input"], ' \
                              '[data-testid="filtered-search-token-segment-input"]'

            def choose_search_user(username)
              within_element('filtered-search-block') do
                find(INPUT_SELECTORS).set(username)
              end
            end

            def choose_pending_approval_filter
              within_element('filtered-search-block') do
                find(INPUT_SELECTORS).click
                click_link('State')
                click_link('Pending approval')
              end
            end

            def click_search
              within_element('filtered-search-block') do
                find_element('search-button').click
              end
              wait_for_requests
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
