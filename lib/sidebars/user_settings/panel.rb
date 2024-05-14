# frozen_string_literal: true

module Sidebars
  module UserSettings
    class Panel < ::Sidebars::Panel
      override :configure_menus
      def configure_menus
        add_menus
      end

      override :aria_label
      def aria_label
        _('User settings')
      end

      override :super_sidebar_context_header
      def super_sidebar_context_header
        aria_label
      end

      private

      def add_menus
        return unless context.current_user

        add_menu(Sidebars::UserSettings::Menus::ProfileMenu.new(context))
        add_menu(Sidebars::UserSettings::Menus::AccountMenu.new(context))
        add_menu(Sidebars::UserSettings::Menus::ApplicationsMenu.new(context))
        add_menu(Sidebars::UserSettings::Menus::ChatMenu.new(context))
        add_menu(Sidebars::UserSettings::Menus::AccessTokensMenu.new(context))
        add_menu(Sidebars::UserSettings::Menus::EmailsMenu.new(context))
        add_menu(Sidebars::UserSettings::Menus::PasswordMenu.new(context))
        add_menu(Sidebars::UserSettings::Menus::NotificationsMenu.new(context))
        add_menu(Sidebars::UserSettings::Menus::SshKeysMenu.new(context))
        add_menu(Sidebars::UserSettings::Menus::GpgKeysMenu.new(context))
        add_menu(Sidebars::UserSettings::Menus::PreferencesMenu.new(context))
        add_menu(Sidebars::UserSettings::Menus::CommentTemplatesMenu.new(context))
        add_menu(Sidebars::UserSettings::Menus::ActiveSessionsMenu.new(context))
        add_menu(Sidebars::UserSettings::Menus::AuthenticationLogMenu.new(context))
        add_menu(Sidebars::UserSettings::Menus::UsageQuotasMenu.new(context))
      end
    end
  end
end

Sidebars::UserSettings::Panel.prepend_mod_with('Sidebars::UserSettings::Panel')
