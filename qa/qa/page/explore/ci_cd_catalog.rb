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
          element 'ci-resource-link'
        end

        view 'app/assets/javascripts/ci/catalog/components/list/catalog_search.vue' do
          element 'catalog-search-bar', required: true
          element 'catalog-sorting-option-button', required: true
        end

        def search_resource(resource_name)
          within_element('catalog-search-bar') do
            # Clicking the term input swaps it for the token segment input, so find the input again
            find_element('filtered-search-term-input').click
            find_element('filtered-search-token-segment-input').set(resource_name)
            click_element('search-button')
          end
          wait_for_requests
        end

        def click_resource_link(resource_name)
          retry_until(reload: true, sleep_interval: 2, max_attempts: 2, message: "Retry for the catalog resource") do
            search_resource(resource_name)
            has_element?('ci-resource-link', text: resource_name)
          end

          find_element('ci-resource-link', text: resource_name).click
        end
      end
    end
  end
end
