# frozen_string_literal: true

module Sidebars
  module Admin
    class BaseMenu < ::Sidebars::Menu
      override :render?
      def render?
        return false unless context.current_user

        context.current_user.can_admin_all_resources?
      end
    end
  end
end
