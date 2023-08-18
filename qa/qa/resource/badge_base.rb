# frozen_string_literal: true

module QA
  module Resource
    class BadgeBase < Base
      attributes :id, :name, :link_url, :image_url

      def initialize
        @name = "qa-badge-#{SecureRandom.hex(8)}"
      end

      def fabricate!
        Page::Component::Badges.perform do |badges|
          badges.show_badge_add_form
          badges.fill_name(name)
          badges.fill_link_url(link_url)
          badges.fill_image_url(image_url)
          badges.click_add_badge_button
        end
      end
    end
  end
end
