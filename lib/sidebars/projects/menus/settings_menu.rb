# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class SettingsMenu < ::Sidebars::Menu
        override :configure_menu_items
        def configure_menu_items
          return false unless can?(context.current_user, :admin_project, context.project)

          add_item(general_menu_item)
          add_item(integrations_menu_item)
          add_item(webhooks_menu_item)
          add_item(access_tokens_menu_item)
          add_item(repository_menu_item)
          add_item(ci_cd_menu_item)
          add_item(monitor_menu_item)
          add_item(pages_menu_item)
          add_item(packages_and_registries_menu_item)

          true
        end

        override :link
        def link
          edit_project_path(context.project)
        end

        override :title
        def title
          _('Settings')
        end

        override :title_html_options
        def title_html_options
          {
            id: 'js-onboarding-settings-link'
          }
        end

        override :sprite_icon
        def sprite_icon
          'settings'
        end

        private

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
            active_routes: { path: %w[integrations#show services#edit] },
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
            title: _('Access Tokens'),
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

        def pages_menu_item
          unless context.project.pages_available?
            return ::Sidebars::NilMenuItem.new(item_id: :pages)
          end

          ::Sidebars::MenuItem.new(
            title: _('Pages'),
            link: project_pages_path(context.project),
            active_routes: { path: 'pages#show' },
            item_id: :pages
          )
        end

        def packages_and_registries_menu_item
          if !Gitlab.config.registry.enabled ||
            !can?(context.current_user, :destroy_container_image, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :packages_and_registries)
          end

          ::Sidebars::MenuItem.new(
            title: _('Packages & Registries'),
            link: project_settings_packages_and_registries_path(context.project),
            active_routes: { path: 'packages_and_registries#index' },
            item_id: :packages_and_registries
          )
        end
      end
    end
  end
end
