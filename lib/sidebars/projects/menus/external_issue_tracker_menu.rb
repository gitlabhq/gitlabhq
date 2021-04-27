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

        override :extra_collapsed_container_html_options
        def extra_collapsed_container_html_options
          {
            target: '_blank',
            rel: 'noopener noreferrer'
          }
        end

        override :title
        def title
          external_issue_tracker.title
        end

        override :title_html_options
        def title_html_options
          {
            id: 'js-onboarding-issues-link'
          }
        end

        override :sprite_icon
        def sprite_icon
          'external-link'
        end

        override :render?
        def render?
          external_issue_tracker.present?
        end

        private

        def external_issue_tracker
          @external_issue_tracker ||= context.project.external_issue_tracker
        end
      end
    end
  end
end
