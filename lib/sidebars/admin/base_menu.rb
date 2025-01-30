# frozen_string_literal: true

module Sidebars
  module Admin
    class BaseMenu < ::Sidebars::Menu
      override :render?
      def render?
        return false unless context.current_user

        render_with_abilities.any? { |ability| context.current_user.can?(ability) }
      end

      private

      def render_with_abilities
        %i[admin_all_resources]
      end
    end
  end
end
