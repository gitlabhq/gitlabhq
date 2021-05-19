# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class ProjectInformationMenu < ::Sidebars::Menu
        override :configure_menu_items
        def configure_menu_items
          add_item(details_menu_item)
          add_item(activity_menu_item)
          add_item(releases_menu_item)
          add_item(labels_menu_item)
          add_item(members_menu_item)

          true
        end

        override :link
        def link
          project_path(context.project)
        end

        override :extra_container_html_options
        def extra_container_html_options
          {
            class: 'shortcuts-project rspec-project-link'
          }
        end

        override :nav_link_html_options
        def nav_link_html_options
          { class: 'home' }
        end

        override :title
        def title
          if Feature.enabled?(:sidebar_refactor, context.current_user)
            _('Project information')
          else
            _('Project overview')
          end
        end

        override :sprite_icon
        def sprite_icon
          if Feature.enabled?(:sidebar_refactor, context.current_user)
            'project'
          else
            'home'
          end
        end

        override :active_routes
        def active_routes
          return {} if Feature.disabled?(:sidebar_refactor, context.current_user)

          { path: 'projects#show' }
        end

        private

        def details_menu_item
          return if Feature.enabled?(:sidebar_refactor, context.current_user)

          ::Sidebars::MenuItem.new(
            title: _('Details'),
            link: project_path(context.project),
            active_routes: { path: 'projects#show' },
            item_id: :project_overview,
            container_html_options: {
              aria: { label: _('Project details') },
              class: 'shortcuts-project'
            }
          )
        end

        def activity_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Activity'),
            link: activity_project_path(context.project),
            active_routes: { path: 'projects#activity' },
            item_id: :activity,
            container_html_options: { class: 'shortcuts-project-activity' }
          )
        end

        def releases_menu_item
          return ::Sidebars::NilMenuItem.new(item_id: :releases) unless show_releases?

          ::Sidebars::MenuItem.new(
            title: _('Releases'),
            link: project_releases_path(context.project),
            item_id: :releases,
            active_routes: { controller: :releases },
            container_html_options: { class: 'shortcuts-project-releases' }
          )
        end

        def show_releases?
          Feature.disabled?(:sidebar_refactor, context.current_user, default_enabled: :yaml) &&
            can?(context.current_user, :read_release, context.project) &&
            !context.project.empty_repo?
        end

        def labels_menu_item
          if Feature.disabled?(:sidebar_refactor, context.current_user)
            return ::Sidebars::NilMenuItem.new(item_id: :labels)
          end

          ::Sidebars::MenuItem.new(
            title: _('Labels'),
            link: project_labels_path(context.project),
            active_routes: { controller: :labels },
            item_id: :labels
          )
        end

        def members_menu_item
          if Feature.disabled?(:sidebar_refactor, context.current_user, default_enabled: :yaml)
            return ::Sidebars::NilMenuItem.new(item_id: :members)
          end

          ::Sidebars::MenuItem.new(
            title: _('Members'),
            link: project_project_members_path(context.project),
            active_routes: { controller: :project_members },
            item_id: :members,
            container_html_options: {
              id: 'js-onboarding-members-link'
            }
          )
        end
      end
    end
  end
end
