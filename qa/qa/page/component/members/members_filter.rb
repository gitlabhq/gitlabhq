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
              element 'search-button'
            end
          end

          def search_member(username)
            filter_input = find('.gl-filtered-search-term-input')
            filter_input.click
            filter_input.set(username)
            click_element 'search-button'
          end
        end
      end
    end
  end
end
