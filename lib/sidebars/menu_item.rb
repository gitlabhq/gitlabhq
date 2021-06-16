# frozen_string_literal: true

module Sidebars
  class MenuItem
    attr_reader :title, :link, :active_routes, :item_id, :container_html_options, :sprite_icon, :sprite_icon_html_options, :hint_html_options

    def initialize(title:, link:, active_routes:, item_id: nil, container_html_options: {}, sprite_icon: nil, sprite_icon_html_options: {}, hint_html_options: {})
      @title = title
      @link = link
      @active_routes = active_routes
      @item_id = item_id
      @container_html_options = { aria: { label: title } }.merge(container_html_options)
      @sprite_icon = sprite_icon
      @sprite_icon_html_options = sprite_icon_html_options
      @hint_html_options = hint_html_options
    end

    def show_hint?
      hint_html_options.present?
    end

    def render?
      true
    end

    def nav_link_html_options
      {
        data: {
          track_label: item_id
        }
      }
    end
  end
end
