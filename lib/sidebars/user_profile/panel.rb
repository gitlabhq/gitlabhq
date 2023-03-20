# frozen_string_literal: true

module Sidebars
  module UserProfile
    class Panel < ::Sidebars::Panel
      include UsersHelper

      override :configure_menus
      def configure_menus
        add_menus
      end

      override :aria_label
      def aria_label
        s_('UserProfile|User profile navigation')
      end

      override :super_sidebar_context_header
      def super_sidebar_context_header
        @super_sidebar_context_header ||= {
          title: user_name,
          avatar: context.container.avatar_url,
          avatar_shape: 'circle'
        }
      end

      private

      def user
        context.container
      end

      def user_name
        return user_display_name(user) if user.blocked? || !user.confirmed?

        user.name
      end

      def add_menus
        add_menu(Sidebars::UserProfile::Menus::OverviewMenu.new(context))
        add_menu(Sidebars::UserProfile::Menus::ActivityMenu.new(context))
        add_menu(Sidebars::UserProfile::Menus::GroupsMenu.new(context))
        add_menu(Sidebars::UserProfile::Menus::ContributedProjectsMenu.new(context))
        add_menu(Sidebars::UserProfile::Menus::PersonalProjectsMenu.new(context))
        add_menu(Sidebars::UserProfile::Menus::StarredProjectsMenu.new(context))
        add_menu(Sidebars::UserProfile::Menus::SnippetsMenu.new(context))
        add_menu(Sidebars::UserProfile::Menus::FollowersMenu.new(context))
        add_menu(Sidebars::UserProfile::Menus::FollowingMenu.new(context))
      end
    end
  end
end
