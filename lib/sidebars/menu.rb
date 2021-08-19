# frozen_string_literal: true

module Sidebars
  class Menu
    extend ::Gitlab::Utils::Override
    include ::Gitlab::Routing
    include GitlabRoutingHelper
    include Gitlab::Allowable
    include ::Sidebars::Concerns::HasPill
    include ::Sidebars::Concerns::HasIcon
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

    # Menus might have or not a link
    override :link
    def link
      nil
    end

    # This method normalizes the information retrieved from the submenus and this menu
    # Value from menus is something like: [{ path: 'foo', path: 'bar', controller: :foo }]
    # This method filters the information and returns: { path: ['foo', 'bar'], controller: :foo }
    def all_active_routes
      @all_active_routes ||= begin
        ([active_routes] + renderable_items.map(&:active_routes)).flatten.each_with_object({}) do |pairs, hash|
          pairs.each do |k, v|
            hash[k] ||= []
            hash[k] += Array(v)
            hash[k].uniq!
          end

          hash
        end
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

    override :container_html_options
    def container_html_options
      super.tap do |html_options|
        # Flagging menus that can be rendered and with renderable menu items
        if render? && has_renderable_items?
          html_options[:class] = [*html_options[:class], 'has-sub-items'].join(' ')
        end
      end
    end

    private

    override :index_of
    def index_of(list, element)
      list.index { |e| e.item_id == element }
    end
  end
end
