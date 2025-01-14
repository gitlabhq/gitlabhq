# frozen_string_literal: true

module QA
  module Page
    module Explore
      class CiCdCatalog < Page::Base
        view 'app/assets/javascripts/ci/catalog/components/list/ci_resources_list.vue' do
          element 'catalog-list-container'
        end

        view 'app/assets/javascripts/ci/catalog/components/list/ci_resources_list_item.vue' do
          element 'catalog-resource-item'
        end

        view 'app/assets/javascripts/ci/catalog/components/list/catalog_search.vue' do
          element 'catalog-search-bar', required: true
          element 'catalog-sorting-option-button', required: true
        end

        def sort_by_created_at
          switch_catalog_sorting_option('CREATED')
        end

        def sort_in_ascending_order
          # Switching from descending to ascending
          click_element('sort-highest-icon')
          wait_for_requests
        end

        def get_top_project_names(count)
          all_elements('ci-resource-link', minimum: 1).first(count).map(&:text)
        end

        def get_bottom_project_names(count)
          all_elements('ci-resource-link', minimum: 1).last(count).map(&:text)
        end

        def click_resource_link(resource_name)
          retry_until(reload: true, sleep_interval: 2, max_attempts: 2, message: "Retry for the catalog resource") do
            has_element?('ci-resource-link', text: resource_name)
          end

          find_element('ci-resource-link', text: resource_name).click
        end

        private

        # Current acceptable options: 'CREATED', 'RELEASED'
        def switch_catalog_sorting_option(option)
          click_element('catalog-sorting-option-button')
          find("[data-testid='listbox-item-#{option}']").click
        end
      end
    end
  end
end
