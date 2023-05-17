# frozen_string_literal: true

module Sidebars
  module UserProfile
    module Menus
      class FollowersMenu < ::Sidebars::UserProfile::BaseMenu
        include Gitlab::Utils::StrongMemoize

        override :link
        def link
          user_followers_path(context.container)
        end

        override :title
        def title
          s_('UserProfile|Followers')
        end

        override :sprite_icon
        def sprite_icon
          'users'
        end

        override :active_routes
        def active_routes
          { path: 'users#followers' }
        end

        override :has_pill?
        def has_pill?
          context.container.followers.any?
        end
        strong_memoize_attr :has_pill?

        override :pill_count
        def pill_count
          context.container.followers.count
        end
        strong_memoize_attr :pill_count
      end
    end
  end
end
