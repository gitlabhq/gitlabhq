# frozen_string_literal: true

module Sidebars # rubocop:disable Gitlab/BoundedContexts -- This has to be named this way
  module UserSettings
    module Menus
      class AccessMenu < ::Sidebars::Menu
        include ::Sidebars::Concerns::RenderIfLoggedIn

        def configure_menu_items
          add_item(password_menu_item)
          add_item(access_tokens_menu_item)
          add_item(ssh_keys_menu_item)
          add_item(gpg_keys_menu_item)
          add_item(applications_menu_item)
          add_item(active_sessions_menu_item)
          add_item(authentication_log_menu_item)

          true
        end

        override :title
        def title
          _('Access')
        end

        override :sprite_icon
        def sprite_icon
          'key'
        end

        private

        def password_menu_item
          unless context.current_user.allow_password_authentication?
            return ::Sidebars::NilMenuItem.new(item_id: :password)
          end

          ::Sidebars::MenuItem.new(
            title: _('Password'),
            link: edit_user_settings_password_path,
            active_routes: { controller: :passwords },
            item_id: :password
          )
        end

        def access_tokens_menu_item
          ::Sidebars::MenuItem.new(
            title: s_('AccessTokens|Personal access tokens'),
            link: user_settings_personal_access_tokens_path,
            active_routes: { controller: :personal_access_tokens },
            item_id: :access_tokens
          )
        end

        def ssh_keys_menu_item
          ::Sidebars::MenuItem.new(
            title: _('SSH keys'),
            link: user_settings_ssh_keys_path,
            active_routes: { controller: :ssh_keys },
            item_id: :ssh_keys
          )
        end

        def gpg_keys_menu_item
          ::Sidebars::MenuItem.new(
            title: _('GPG keys'),
            link: user_settings_gpg_keys_path,
            active_routes: { controller: :gpg_keys },
            item_id: :gpg_keys
          )
        end

        def applications_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Applications'),
            link: user_settings_applications_path,
            active_routes: { controller: 'oauth/applications' },
            item_id: :applications
          )
        end

        def authentication_log_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Authentication log'),
            link: user_settings_authentication_log_path,
            active_routes: { path: 'user_settings#authentication_log' },
            item_id: :authentication_log
          )
        end

        def active_sessions_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Active sessions'),
            link: user_settings_active_sessions_path,
            active_routes: { controller: :active_sessions },
            item_id: :active_sessions
          )
        end
      end
    end
  end
end

Sidebars::UserSettings::Menus::AccessMenu.prepend_mod
