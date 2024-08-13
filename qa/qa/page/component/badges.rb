# frozen_string_literal: true

module QA
  module Page
    module Component
      class Badges < Page::Base
        view 'app/assets/javascripts/badges/components/badge_form.vue' do
          element 'badge-name-field'
          element 'badge-link-url-field'
          element 'badge-image-url-field'
          element 'add-badge-button'
        end

        view 'app/assets/javascripts/badges/components/badge_list.vue' do
          element 'badge-list-content'
          element 'badge-list'
        end

        view 'app/assets/javascripts/badges/components/badge.vue' do
          element 'badge-image-link'
        end

        def show_badge_add_form
          click_element 'crud-form-toggle'
        end

        def fill_name(name)
          fill_element 'badge-name-field', name
        end

        def fill_link_url(url)
          fill_element 'badge-link-url-field', url
        end

        def fill_image_url(url)
          fill_element 'badge-image-url-field', url
        end

        def click_add_badge_button
          click_element 'add-badge-button'
        end

        def has_badge?(badge_name)
          within_element('badge-list-content') do
            has_element?('badge-list', text: badge_name)
          end
        end

        def has_visible_badge_image_link?(link_url)
          within_element('badge-list-content') do
            has_element?('badge-image-link', link_url: link_url)
          end
        end
      end
    end
  end
end
