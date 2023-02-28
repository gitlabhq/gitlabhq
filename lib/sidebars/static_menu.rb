# frozen_string_literal: true

module Sidebars
  # This is a special menu which does not serialize as
  # a section and instead hoists all of menu items
  # to be top-level items
  class StaticMenu < ::Sidebars::Menu
    override :serialize_for_super_sidebar
    def serialize_for_super_sidebar
      serialize_items_for_super_sidebar
    end
  end
end
