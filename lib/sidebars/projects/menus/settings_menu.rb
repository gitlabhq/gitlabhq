# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class SettingsMenu < ::Sidebars::Menu
        override :configure_menu_items
        def configure_menu_items
          return false if enabled_menu_items.empty?

          enabled_menu_items.each do |menu_item|
            add_item(menu_item)
          end
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

        override :pick_into_super_sidebar?
        def pick_into_super_sidebar?
          true
        end

        override :separated?
        def separated?
          true
        end

        private

        def enabled_menu_items
          if can?(context.current_user, :admin_project, context.project)
            [
              general_menu_item,
              integrations_menu_item,
              webhooks_menu_item,
              access_tokens_menu_item,
              repository_menu_item,
              merge_requests_menu_item,
              ci_cd_menu_item,
              packages_and_registries_menu_item,
              monitor_menu_item,
              usage_quotas_menu_item
            ]
          else
            []
          end
        end

        def general_menu_item
          ::Sidebars::MenuItem.new(
            title: _('General'),
            link: edit_project_path(context.project),
            active_routes: { path: 'projects#edit' },
            item_id: :general
          )
        end

        def integrations_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Integrations'),
            link: project_settings_integrations_path(context.project),
            active_routes: { path: %w[integrations#index integrations#edit] },
            item_id: :integrations
          )
        end

        def webhooks_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Webhooks'),
            link: project_hooks_path(context.project),
            active_routes: { path: %w[hooks#index hooks#edit hook_logs#show] },
            item_id: :webhooks
          )
        end

        def access_tokens_menu_item
          unless can?(context.current_user, :read_resource_access_tokens, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :access_tokens)
          end

          ::Sidebars::MenuItem.new(
            title: _('Access tokens'),
            link: project_settings_access_tokens_path(context.project),
            active_routes: { path: 'access_tokens#index' },
            item_id: :access_tokens
          )
        end

        def repository_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Repository'),
            link: project_settings_repository_path(context.project),
            active_routes: { path: 'repository#show' },
            item_id: :repository
          )
        end

        def ci_cd_menu_item
          if context.project.archived? || !context.project.feature_available?(:builds, context.current_user)
            return ::Sidebars::NilMenuItem.new(item_id: :ci_cd)
          end

          ::Sidebars::MenuItem.new(
            title: _('CI/CD'),
            link: project_settings_ci_cd_path(context.project),
            active_routes: { path: 'ci_cd#show' },
            item_id: :ci_cd
          )
        end

        def packages_and_registries_menu_item
          unless can?(context.current_user, :view_package_registry_project_settings, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :packages_and_registries)
          end

          ::Sidebars::MenuItem.new(
            title: _('Packages and registries'),
            link: project_settings_packages_and_registries_path(context.project),
            active_routes: { controller: :packages_and_registries },
            item_id: :packages_and_registries
          )
        end

        def monitor_menu_item
          if context.project.archived? || !can?(context.current_user, :admin_operations, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :monitor)
          end

          ::Sidebars::MenuItem.new(
            title: _('Monitor'),
            link: project_settings_operations_path(context.project),
            active_routes: { path: 'operations#show' },
            item_id: :monitor
          )
        end

        def usage_quotas_menu_item
          ::Sidebars::MenuItem.new(
            title: s_('UsageQuota|Usage Quotas'),
            link: project_usage_quotas_path(context.project),
            active_routes: { path: 'usage_quotas#index' },
            item_id: :usage_quotas
          )
        end

        def merge_requests_menu_item
          return unless context.project.merge_requests_enabled?

          ::Sidebars::MenuItem.new(
            title: _('Merge requests'),
            link: project_settings_merge_requests_path(context.project),
            active_routes: { path: 'projects/settings/merge_requests#show' },
            item_id: context.is_super_sidebar ? :merge_request_settings : :merge_requests
          )
        end
      end
    end
  end
end

Sidebars::Projects::Menus::SettingsMenu.prepend_mod_with('Sidebars::Projects::Menus::SettingsMenu')
