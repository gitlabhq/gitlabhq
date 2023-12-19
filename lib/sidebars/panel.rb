# frozen_string_literal: true

module Sidebars
  class Panel
    extend ::Gitlab::Utils::Override
    include ::Sidebars::Concerns::PositionableList

    attr_reader :context, :scope_menu, :hidden_menu

    def initialize(context)
      @context = context
      @scope_menu = nil
      @hidden_menu = nil
      @menus = []

      configure_menus
    end

    def configure_menus
      # No-op
    end

    def add_menu(menu)
      add_element(@menus, menu)
    end

    def insert_menu_before(before_menu, new_menu)
      insert_element_before(@menus, before_menu, new_menu)
    end

    def insert_menu_after(after_menu, new_menu)
      insert_element_after(@menus, after_menu, new_menu)
    end

    def replace_menu(menu_to_replace, new_menu)
      replace_element(@menus, menu_to_replace, new_menu)
    end

    def remove_menu(menu_to_remove)
      remove_element(@menus, menu_to_remove)
    end

    def set_scope_menu(scope_menu)
      @scope_menu = scope_menu
    end

    def set_hidden_menu(hidden_menu)
      @hidden_menu = hidden_menu
    end

    def aria_label
      raise NotImplementedError
    end

    def render?
      renderable_menus.any?
    end

    def renderable_menus
      @renderable_menus ||= @menus.select(&:render?)
    end

    # Serializes every renderable menu and returns a flattened result
    def super_sidebar_menu_items
      @super_sidebar_menu_items ||= renderable_menus
        .flat_map(&:serialize_for_super_sidebar)
    end

    def super_sidebar_context_header
      raise NotImplementedError
    end

    def container
      context.container
    end

    private

    override :index_of
    def index_of(list, element)
      list.index { |e| e.is_a?(element) }
    end
  end
end
