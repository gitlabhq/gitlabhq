# frozen_string_literal: true

module Sidebars # rubocop:disable Gitlab/BoundedContexts -- Sidebar menus follow the existing Sidebars::Admin::Menus namespace
  module Admin
    module Menus
      class SshCertificatesMenu < ::Sidebars::Admin::BaseMenu
        override :link
        def link
          admin_ssh_certificates_path
        end

        override :title
        def title
          _('SSH certificate authorities')
        end

        override :sprite_icon
        def sprite_icon
          'key'
        end

        override :active_routes
        def active_routes
          { controller: :ssh_certificates }
        end
      end
    end
  end
end
