# frozen_string_literal: true

module QA
  module Page
    module Component
      module NamespaceSelect
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view "app/assets/javascripts/groups_projects/components/transfer_locations.vue" do
            element 'transfer-locations-dropdown'
            element 'transfer-locations-search'
            element 'group-transfer-item'
          end
        end

        def select_namespace(item)
          click_element 'transfer-locations-dropdown'

          within_element('transfer-locations-dropdown') do
            fill_element('transfer-locations-search', item)

            wait_for_requests

            # Click element by JS in case dropdown changes position mid-click
            # Workaround for issue https://gitlab.com/gitlab-org/gitlab/-/issues/381376
            namespace = find_element('group-transfer-item', text: item, visible: false)
            click_by_javascript(namespace)
          end
        end
      end
    end
  end
end
