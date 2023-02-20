# frozen_string_literal: true

module QA
  module Page
    module Component
      module Members
        module MembersFilter
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.view 'app/assets/javascripts/members/components/filter_sort/members_filtered_search_bar.vue' do
              element :search_bar_input
              element :search_button
            end
          end

          def search_member(username)
            fill_element :search_bar_input, username
            click_element :search_button
          end
        end
      end
    end
  end
end
