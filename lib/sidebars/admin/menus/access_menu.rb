# frozen_string_literal: true

module Sidebars # rubocop:disable Gitlab/BoundedContexts -- Sidebar menus follow the existing Sidebars::Admin::Menus namespace
  module Admin
    module Menus
      class AccessMenu < ::Sidebars::Admin::BaseMenu
        override :configure_menu_items
        def configure_menu_items
          add_item(deploy_keys_menu_item)
          add_item(ssh_certificates_menu_item)
          true
        end

        override :title
        def title
          s_('Admin|Access')
        end

        override :sprite_icon
        def sprite_icon
          'shield'
        end

        override :extra_container_html_options
        def extra_container_html_options
          { testid: 'admin-access-menu-link' }
        end

        private

        def deploy_keys_menu_item
          build_menu_item(
            title: s_('Admin|Deploy keys'),
            link: admin_deploy_keys_path,
            active_routes: { controller: :deploy_keys },
            item_id: :deploy_keys
          )
        end

        def ssh_certificates_menu_item
          build_menu_item(
            title: s_('SshCertificates|Certificate authorities'),
            link: admin_ssh_certificates_path,
            active_routes: { controller: :ssh_certificates },
            item_id: :ssh_certificates
          ) { InstanceSshCertificate.available? }
        end
      end
    end
  end
end

Sidebars::Admin::Menus::AccessMenu.prepend_mod_with('Sidebars::Admin::Menus::AccessMenu')
