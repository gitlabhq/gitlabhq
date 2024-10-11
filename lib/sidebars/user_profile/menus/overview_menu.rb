# frozen_string_literal: true

module Sidebars
  module UserProfile
    module Menus
      class OverviewMenu < ::Sidebars::UserProfile::BaseMenu
        include ::UsersHelper

        override :link
        def link
          user_path(user)
        end

        override :title
        def title
          user_name
        end

        override :avatar
        def avatar
          user.avatar_url
        end

        override :avatar_shape
        def avatar_shape
          'circle'
        end

        override :entity_id
        def entity_id
          user.id
        end

        override :active_routes
        def active_routes
          { path: 'users#show' }
        end

        private

        def user
          context.container
        end

        def user_name
          return user_display_name(user) if user.blocked? || !user.confirmed?

          user.name
        end
      end
    end
  end
end
