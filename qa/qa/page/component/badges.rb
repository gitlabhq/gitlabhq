# frozen_string_literal: true

module QA
  module Page
    module Component
      class Badges < Page::Base
        view 'app/assets/javascripts/badges/components/badge_form.vue' do
          element :badge_name_field
          element :badge_link_url_field
          element :badge_image_url_field
          element :add_badge_button
        end

        view 'app/assets/javascripts/badges/components/badge_list.vue' do
          element :badge_list_content
          element :badge_list_row
        end

        view 'app/assets/javascripts/badges/components/badge.vue' do
          element :badge_image_link
        end

        def fill_name(name)
          fill_element :badge_name_field, name
        end

        def fill_link_url(url)
          fill_element :badge_link_url_field, url
        end

        def fill_image_url(url)
          fill_element :badge_image_url_field, url
        end

        def click_add_badge_button
          click_element :add_badge_button
        end

        def has_badge?(badge_name)
          within_element(:badge_list_content) do
            has_element?(:badge_list_row, badge_name: badge_name)
          end
        end

        def has_visible_badge_image_link?(link_url)
          within_element(:badge_list_content) do
            has_element?(:badge_image_link, link_url: link_url)
          end
        end
      end
    end
  end
end
