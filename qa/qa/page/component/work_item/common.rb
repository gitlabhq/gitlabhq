# frozen_string_literal: true

module QA
  module Page
    module Component
      module WorkItem
        module Common
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.view 'app/assets/javascripts/work_items/components/item_title.vue' do
              element 'work-item-title', required: true
            end
          end
        end
      end
    end
  end
end
