# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class MembersMenu < ::Sidebars::Menu
        override :link
        def link
          project_project_members_path(context.project)
        end

        override :extra_container_html_options
        def extra_container_html_options
          {
            id: 'js-onboarding-members-link'
          }
        end

        override :title
        def title
          _('Members')
        end

        override :sprite_icon
        def sprite_icon
          'users'
        end

        override :render?
        def render?
          return false if Feature.enabled?(:sidebar_refactor, context.current_user, default_enabled: :yaml)

          can?(context.current_user, :read_project_member, context.project)
        end

        override :active_routes
        def active_routes
          { controller: :project_members }
        end
      end
    end
  end
end
