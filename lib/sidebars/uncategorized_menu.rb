# frozen_string_literal: true

module Sidebars
  # This Menu is a temporary help while we implement the new menu
  # categories for everything. Once every Menu Item is categorized,
  # we can remove this. This should be done before the Super Sidebar
  # moves out of Alpha.
  class UncategorizedMenu < ::Sidebars::Menu
    override :title
    def title
      _('Uncategorized')
    end

    override :sprite_icon
    def sprite_icon
      'question'
    end
  end
end
