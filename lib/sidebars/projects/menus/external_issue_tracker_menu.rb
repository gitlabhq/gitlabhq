# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class ExternalIssueTrackerMenu < ::Sidebars::Menu
        override :link
        def link
          external_issue_tracker.issue_tracker_path
        end

        override :extra_container_html_options
        def extra_container_html_options
          {
            target: '_blank',
            rel: 'noopener noreferrer',
            class: 'shortcuts-external_tracker'
          }
        end

        override :title
        def title
          return s_('JiraService|Jira') if external_issue_tracker.is_a?(Integrations::Jira)

          external_issue_tracker.title
        end

        override :sprite_icon
        def sprite_icon
          'external-link'
        end

        override :render?
        def render?
          external_issue_tracker.present?
        end

        override :serialize_as_menu_item_args
        def serialize_as_menu_item_args
          super.merge({
            item_id: :external_issue_tracker,
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::PlanMenu
          })
        end

        private

        def external_issue_tracker
          @external_issue_tracker ||= context.project.external_issue_tracker
        end
      end
    end
  end
end
