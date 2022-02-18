# frozen_string_literal: true

module QA
  module Page
    module Component
      module MembersFilter
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/assets/javascripts/members/components/filter_sort/members_filtered_search_bar.vue' do
            element :members_filtered_search_bar_content
          end
        end

        def search_member(username)
          # TODO: Update the two actions below to use direct qa selectors once this is implemented:
          # https://gitlab.com/gitlab-org/gitlab-ui/-/issues/1688
          find_element(:members_filtered_search_bar_content).find('input').set(username)
          find('.gl-search-box-by-click-search-button').click
        end
      end
    end
  end
end
