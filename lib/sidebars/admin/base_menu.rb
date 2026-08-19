# frozen_string_literal: true

module Sidebars
  module Admin
    class BaseMenu < ::Sidebars::Menu
      override :render?
      def render?
        return false unless context.current_user

        render_with_abilities.any? { |ability| can?(context.current_user, ability, authorization_subject) }
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

      # The authorization subject for admin ability checks. Defaults to
      # `:global` for the instance admin area. The organization admin area
      # overrides this to return the current organization.
      def authorization_subject
        :global
      end

      def render_with_abilities
        %i[admin_all_resources]
      end
    end
  end
end
