# frozen_string_literal: true

module QA
  module Page
    module SubMenus
      module Explore
        extend QA::Page::PageConcern

        def self.prepended(base)
          super

          base.class_eval do
            view 'app/assets/javascripts/super_sidebar/components/nav_item.vue' do
              element 'nav-item-link'
            end
          end
        end

        def go_to_ci_cd_catalog
          click_element('nav-item-link', submenu_item: 'CI/CD Catalog')
        end
      end
    end
  end
end
