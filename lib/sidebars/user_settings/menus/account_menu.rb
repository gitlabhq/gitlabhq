# frozen_string_literal: true

module Sidebars
  module UserSettings
    module Menus
      class AccountMenu < ::Sidebars::Menu
        include ::Sidebars::Concerns::RenderIfLoggedIn

        override :link
        def link
          profile_account_path
        end

        override :title
        def title
          _('Account')
        end

        override :sprite_icon
        def sprite_icon
          'account'
        end

        override :active_routes
        def active_routes
          { controller: [:accounts, :two_factor_auths] }
        end

        override :extra_container_html_options
        def extra_container_html_options
          { 'data-testid': 'profile_account_link' }
        end
      end
    end
  end
end
