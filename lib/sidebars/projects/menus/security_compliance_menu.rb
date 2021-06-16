# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class SecurityComplianceMenu < ::Sidebars::Menu
        include Gitlab::Utils::StrongMemoize

        override :configure_menu_items
        def configure_menu_items
          return false unless can?(context.current_user, :access_security_and_compliance, context.project)

          add_item(configuration_menu_item)

          true
        end

        override :link
        def link
          renderable_items.first&.link
        end

        override :title
        def title
          _('Security & Compliance')
        end

        override :sprite_icon
        def sprite_icon
          'shield'
        end

        private

        def configuration_menu_item
          unless render_configuration_menu_item?
            return ::Sidebars::NilMenuItem.new(item_id: :configuration)
          end

          ::Sidebars::MenuItem.new(
            title: _('Configuration'),
            link: project_security_configuration_path(context.project),
            active_routes: { path: configuration_menu_item_paths },
            item_id: :configuration
          )
        end

        def render_configuration_menu_item?
          can?(context.current_user, :read_security_configuration, context.project)
        end

        def configuration_menu_item_paths
          %w[
            projects/security/configuration#show
          ]
        end
      end
    end
  end
end

Sidebars::Projects::Menus::SecurityComplianceMenu.prepend_mod_with('Sidebars::Projects::Menus::SecurityComplianceMenu')
