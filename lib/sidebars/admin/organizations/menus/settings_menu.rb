# frozen_string_literal: true

module Sidebars
  module Admin
    module Organizations
      module Menus
        class SettingsMenu < ::Sidebars::Admin::BaseMenu
          override :configure_menu_items
          def configure_menu_items
            add_item(general_menu_item)

            true
          end

          override :title
          def title
            _('Settings')
          end

          override :sprite_icon
          def sprite_icon
            'settings'
          end

          private

          override :authorization_subject
          def authorization_subject
            context.current_organization
          end

          override :render_with_abilities
          def render_with_abilities
            %i[access_organization_admin_area]
          end

          def general_menu_item
            build_menu_item(
              title: _('General'),
              link: general_organization_admin_settings_path(context.current_organization),
              active_routes: { controller: 'admin/organizations/settings' },
              item_id: :organization_admin_settings_general
            )
          end
        end
      end
    end
  end
end
