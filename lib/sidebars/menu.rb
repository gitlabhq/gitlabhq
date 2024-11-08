# frozen_string_literal: true

module Sidebars
  class Menu
    extend ::Gitlab::Utils::Override
    include ::Gitlab::Routing
    include GitlabRoutingHelper
    include Gitlab::Allowable
    include ::Sidebars::Concerns::HasPill
    include ::Sidebars::Concerns::HasIcon
    include ::Sidebars::Concerns::HasAvatar
    include ::Sidebars::Concerns::PositionableList
    include ::Sidebars::Concerns::Renderable
    include ::Sidebars::Concerns::ContainerWithHtmlOptions
    include ::Sidebars::Concerns::HasActiveRoutes
    include ::Sidebars::Concerns::HasPartial

    attr_reader :context

    delegate :current_user, :container, to: :@context

    def initialize(context)
      @context = context
      @items = []

      configure_menu_items
    end

    def configure_menu_items
      true
    end

    override :render?
    def render?
      has_renderable_items? || menu_with_partial?
    end

    override :link
    def link
      renderable_items.first&.link
    end

    # This method normalizes the information retrieved from the submenus and this menu
    # Value from menus is something like: [{ path: 'foo', path: 'bar', controller: :foo }]
    # This method filters the information and returns: { path: ['foo', 'bar'], controller: :foo }
    def all_active_routes
      @all_active_routes ||=
        ([active_routes] + renderable_items.map(&:active_routes)).flatten.each_with_object({}) do |pairs, hash|
          pairs.each do |k, v|
            hash[k] ||= []
            hash[k] += Array(v)
            hash[k].uniq!
          end

          hash
        end
    end

    # Returns whether the menu has any menu item, no
    # matter whether it is renderable or not
    def has_items?
      @items.any?
    end

    # Returns all renderable menu items
    def renderable_items
      @renderable_items ||= @items.select(&:render?)
    end

    # Defines whether menu is separated from others with a top separator
    def separated?
      false
    end

    # Returns a tree-like representation of itself and all
    # renderable menu entries, with additional information
    # on whether the item(s) have an active route
    def serialize_for_super_sidebar
      items = serialize_items_for_super_sidebar
      is_active = @context.route_is_active.call(active_routes) || items.any? { |item| item[:is_active] }

      {
        id: self.class.name.demodulize.underscore,
        title: title,
        icon: sprite_icon,
        avatar: avatar,
        avatar_shape: avatar_shape,
        entity_id: entity_id,
        link: link,
        is_active: is_active,
        pill_count: has_pill? ? pill_count : nil,
        pill_count_field: has_pill? ? pill_count_field : nil,
        items: items,
        separated: separated?
      }.compact
    end

    # Returns an array of renderable menu entries,
    # with additional information on whether the item
    # has an active route
    def serialize_items_for_super_sidebar
      # All renderable menu entries
      renderable_items.map do |entry|
        entry.serialize_for_super_sidebar.tap do |item|
          active_routes = item.delete(:active_routes)
          item[:is_active] = active_routes ? @context.route_is_active.call(active_routes) : false
        end
      end
    end

    def pick_into_super_sidebar?
      false
    end

    # Returns whether the menu has any renderable menu item
    def has_renderable_items?
      renderable_items.any?
    end

    def add_item(item)
      add_element(@items, item)
    end

    def insert_item_before(before_item, new_item)
      insert_element_before(@items, before_item, new_item)
    end

    def insert_item_after(after_item, new_item)
      insert_element_after(@items, after_item, new_item)
    end

    def remove_item(item)
      remove_element(@items, item.item_id)
    end

    def replace_placeholder(item)
      idx = @items.index { |e| e.item_id == item.item_id && e.is_a?(::Sidebars::NilMenuItem) }
      if idx.nil?
        add_item(item)
      else
        replace_element(@items, item.item_id, item)
      end
    end

    override :container_html_options
    def container_html_options
      super.tap do |html_options|
        # Flagging menus that can be rendered and with renderable menu items
        if render? && has_renderable_items?
          html_options[:class] = [*html_options[:class], 'has-sub-items'].join(' ')
        end
      end
    end

    # Sometimes we want to convert a top-level Menu (e.g. Wiki/Snippets)
    # to a MenuItem. This serializer is used in order to enable that conversion
    def serialize_as_menu_item_args
      {
        title: title,
        link: link,
        active_routes: active_routes,
        container_html_options: container_html_options
      }
    end

    private

    override :index_of
    def index_of(list, element)
      list.index { |e| e.item_id == element }
    end
  end
end
