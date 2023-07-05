# frozen_string_literal: true

module Sidebars
  module UserSettings
    module Menus
      class EmailsMenu < ::Sidebars::Menu
        include ::Sidebars::Concerns::RenderIfLoggedIn

        override :link
        def link
          profile_emails_path
        end

        override :title
        def title
          _('Emails')
        end

        override :sprite_icon
        def sprite_icon
          'mail'
        end

        override :active_routes
        def active_routes
          { controller: :emails }
        end

        override :extra_container_html_options
        def extra_container_html_options
          { 'data-testid': 'profile_emails_link' }
        end
      end
    end
  end
end
