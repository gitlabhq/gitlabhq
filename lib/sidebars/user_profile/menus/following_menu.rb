# frozen_string_literal: true

module Sidebars
  module UserProfile
    module Menus
      class FollowingMenu < ::Sidebars::UserProfile::BaseMenu
        include Gitlab::Utils::StrongMemoize

        override :link
        def link
          user_following_path(context.container)
        end

        override :title
        def title
          s_('UserProfile|Following')
        end

        override :sprite_icon
        def sprite_icon
          'users'
        end

        override :active_routes
        def active_routes
          { path: 'users#following' }
        end

        override :has_pill?
        def has_pill?
          context.container.followees.any?
        end
        strong_memoize_attr :has_pill?

        override :pill_count
        def pill_count
          context.container.followees.count
        end
        strong_memoize_attr :pill_count
      end
    end
  end
end
