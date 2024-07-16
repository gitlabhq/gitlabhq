# frozen_string_literal: true

# rubocop:disable Search/NamespacedClass
module QA
  module Page
    module SubMenus
      module SuperSidebar
        module GlobalSearchModal
          extend QA::Page::PageConcern

          def self.prepended(base)
            super

            base.class_eval do
              view 'app/assets/javascripts/super_sidebar/components/global_search/' \
                   'components/global_search_default_places.vue' do
                element :_, "'data-qa-places-item': title" # rubocop:disable QA/ElementWithPattern
                element 'places-item-link'
              end

              view 'app/assets/javascripts/super_sidebar/components/global_search/components/global_search.vue' do
                element 'global-search-input'
              end

              view 'app/assets/javascripts/super_sidebar/components/user_bar.vue' do
                element 'super-sidebar-search-button'
              end
            end
          end

          def go_to_your_work
            go_to_places_item("Your work")
          end

          def go_to_explore
            go_to_places_item("Explore")
          end

          def go_to_admin_area
            go_to_places_item("Admin area")

            return unless has_text?('Enter admin mode', wait: 1.0)

            Admin::NewSession.perform do |new_session|
              new_session.set_password(Runtime::User.admin_password)
              new_session.click_enter_admin_mode
            end
          end

          def has_admin_area_link?(wait: Capybara.default_max_wait_time)
            open_global_search_modal

            has_element?('places-item-link', places_item: "Admin area", wait: wait)
          end

          def search_for(term)
            click_element('super-sidebar-search-button')
            fill_element('global-search-input', "#{term}\n")
          end

          def close_global_search_modal_if_shown
            find_element('global-search-input').send_keys(:escape) if has_element?('global-search-input', wait: 1)
          end

          private

          def go_to_places_item(places_item)
            open_global_search_modal
            click_element('places-item-link', places_item: places_item)
          end

          def open_global_search_modal
            click_element('super-sidebar-search-button')
          end
        end
      end
    end
  end
end
# rubocop:enable Search/NamespacedClass
