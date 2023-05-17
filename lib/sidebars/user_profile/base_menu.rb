# frozen_string_literal: true

module Sidebars
  module UserProfile
    class BaseMenu < ::Sidebars::Menu
      override :render?
      def render?
        can?(context.current_user, :read_user_profile, context.container)
      end
    end
  end
end
