# frozen_string_literal: true

module Sidebars
  module Search
    class Panel < ::Sidebars::Panel
      override :aria_label
      def aria_label
        _('Search results')
      end

      # The Search Panel is a special candidate and renderable,
      # even though it has no backend-defined menus.
      # It will receive it's menu items in the frontend
      override :render?
      def render?
        true
      end

      override :super_sidebar_context_header
      def super_sidebar_context_header
        aria_label
      end
    end
  end
end
