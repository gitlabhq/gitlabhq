# frozen_string_literal: true

module Sidebars
  module Admin
    class BaseMenu < ::Sidebars::Menu
      override :render?
      def render?
        return false unless context.current_user

        render_with_abilities.any? { |ability| context.current_user.can?(ability) }
      end

      protected

      def build_menu_item(**args)
        return nil_item(args[:item_id]) if block_given? && !yield

        ::Sidebars::MenuItem.new(**args)
      end

      def nil_item(id)
        ::Sidebars::NilMenuItem.new(item_id: id)
      end

      private

      def render_with_abilities
        %i[admin_all_resources]
      end
    end
  end
end
