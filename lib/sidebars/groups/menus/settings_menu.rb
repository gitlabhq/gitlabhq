# frozen_string_literal: true

module Sidebars
  module Groups
    module Menus
      class SettingsMenu < ::Sidebars::Menu
        override :configure_menu_items
        def configure_menu_items
          return unless can?(context.current_user, :admin_group, context.group)

          add_item(general_menu_item)
          add_item(integrations_menu_item)
          add_item(access_tokens_menu_item)
          add_item(group_projects_menu_item)
          add_item(repository_menu_item)
          add_item(ci_cd_menu_item)
          add_item(applications_menu_item)
          add_item(packages_and_registries_menu_item)
          add_item(usage_quotas_menu_item)
        end

        override :title
        def title
          _('Settings')
        end

        override :sprite_icon
        def sprite_icon
          'settings'
        end

        override :pick_into_super_sidebar?
        def pick_into_super_sidebar?
          true
        end

        override :separated?
        def separated?
          true
        end

        private

        def general_menu_item
          ::Sidebars::MenuItem.new(
            title: _('General'),
            link: edit_group_path(context.group),
            active_routes: { path: 'groups#edit' },
            item_id: :general
          )
        end

        def integrations_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Integrations'),
            link: group_settings_integrations_path(context.group),
            active_routes: { controller: :integrations },
            item_id: :integrations
          )
        end

        def access_tokens_menu_item
          unless can?(context.current_user, :read_resource_access_tokens, context.group)
            return ::Sidebars::NilMenuItem.new(item_id: :access_tokens)
          end

          ::Sidebars::MenuItem.new(
            title: _('Access tokens'),
            link: group_settings_access_tokens_path(context.group),
            active_routes: { path: 'access_tokens#index' },
            item_id: :access_tokens
          )
        end

        def group_projects_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Projects'),
            link: projects_group_path(context.group),
            active_routes: { path: 'groups#projects' },
            item_id: :group_projects
          )
        end

        def repository_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Repository'),
            link: group_settings_repository_path(context.group),
            active_routes: { controller: :repository },
            item_id: :repository
          )
        end

        def ci_cd_menu_item
          ::Sidebars::MenuItem.new(
            title: _('CI/CD'),
            link: group_settings_ci_cd_path(context.group),
            active_routes: { path: 'ci_cd#show' },
            item_id: :ci_cd
          )
        end

        def applications_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Applications'),
            link: group_settings_applications_path(context.group),
            active_routes: { controller: :applications },
            item_id: :applications
          )
        end

        def usage_quotas_menu_item
          return ::Sidebars::NilMenuItem.new(item_id: :usage_quotas) unless context.group.usage_quotas_enabled?

          ::Sidebars::MenuItem.new(
            title: s_('UsageQuota|Usage Quotas'),
            link: group_usage_quotas_path(context.group),
            active_routes: { path: 'usage_quotas#index' },
            item_id: :usage_quotas
          )
        end

        def packages_and_registries_menu_item
          unless context.group.packages_feature_enabled?
            return ::Sidebars::NilMenuItem.new(item_id: :packages_and_registries)
          end

          ::Sidebars::MenuItem.new(
            title: _('Packages and registries'),
            link: group_settings_packages_and_registries_path(context.group),
            active_routes: { controller: :packages_and_registries },
            item_id: :packages_and_registries
          )
        end
      end
    end
  end
end

Sidebars::Groups::Menus::SettingsMenu.prepend_mod_with('Sidebars::Groups::Menus::SettingsMenu')
