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

    def set_scope_menu(scope_menu)
      @scope_menu = scope_menu
    end

    def set_hidden_menu(hidden_menu)
      @hidden_menu = hidden_menu
    end

    def aria_label
      raise NotImplementedError
    end

    def has_renderable_menus?
      renderable_menus.any?
    end

    def renderable_menus
      @renderable_menus ||= @menus.select(&:render?)
    end

    def container
      context.container
    end

    # Auxiliar method that helps with the migration from
    # regular views to the new logic
    def render_raw_scope_menu_partial
      # No-op
    end

    # Auxiliar method that helps with the migration from
    # regular views to the new logic.
    #
    # Any menu inside this partial will be added after
    # all the menus added in the `configure_menus`
    # method.
    def render_raw_menus_partial
      # No-op
    end

    private

    override :index_of
    def index_of(list, element)
      list.index { |e| e.is_a?(element) }
    end
  end
end
