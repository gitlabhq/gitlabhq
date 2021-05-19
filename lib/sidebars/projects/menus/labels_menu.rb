# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class LabelsMenu < ::Sidebars::Menu
        override :link
        def link
          project_labels_path(context.project)
        end

        override :extra_container_html_options
        def extra_container_html_options
          {
            class: 'shortcuts-labels'
          }
        end

        override :title
        def title
          _('Labels')
        end

        override :title_html_options
        def title_html_options
          {
            id: 'js-onboarding-labels-link'
          }
        end

        override :active_routes
        def active_routes
          { controller: :labels }
        end

        override :sprite_icon
        def sprite_icon
          'label'
        end

        override :render?
        def render?
          return false if Feature.enabled?(:sidebar_refactor, context.current_user)

          can?(context.current_user, :read_label, context.project) && !context.project.issues_enabled?
        end
      end
    end
  end
end
