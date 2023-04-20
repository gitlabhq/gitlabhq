# frozen_string_literal: true

module Sidebars
  class MenuItem
    include ::Sidebars::Concerns::LinkWithHtmlOptions

    attr_reader :title, :link, :active_routes, :item_id, :container_html_options, :sprite_icon, :sprite_icon_html_options, :hint_html_options, :has_pill, :pill_count, :super_sidebar_parent
    alias_method :has_pill?, :has_pill

    # rubocop: disable Metrics/ParameterLists
    def initialize(title:, link:, active_routes:, item_id: nil, container_html_options: {}, sprite_icon: nil, sprite_icon_html_options: {}, hint_html_options: {}, has_pill: false, pill_count: nil, super_sidebar_parent: nil)
      @title = title
      @link = link
      @active_routes = active_routes
      @item_id = item_id
      @container_html_options = { aria: { label: title } }.merge(container_html_options)
      @sprite_icon = sprite_icon
      @sprite_icon_html_options = sprite_icon_html_options
      @hint_html_options = hint_html_options
      @has_pill = has_pill
      @pill_count = pill_count
      @super_sidebar_parent = super_sidebar_parent
    end
    # rubocop: enable Metrics/ParameterLists

    def show_hint?
      hint_html_options.present?
    end

    def render?
      true
    end

    def serialize_for_super_sidebar
      {
        id: item_id,
        title: title,
        icon: sprite_icon,
        link: link,
        active_routes: active_routes,
        pill_count: has_pill ? pill_count : nil,
        link_classes: container_html_options[:class]
        # Check whether support is needed for the following properties,
        # in order to get feature parity with the HAML renderer
        # https://gitlab.com/gitlab-org/gitlab/-/issues/391864
        #
        # container_html_options
        # hint_html_options
        # nav_link_html_options
      }
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
