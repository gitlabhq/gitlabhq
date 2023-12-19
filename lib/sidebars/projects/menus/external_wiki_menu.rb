# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class ExternalWikiMenu < ::Sidebars::Menu
        override :link
        def link
          external_wiki.external_wiki_url
        end

        override :extra_container_html_options
        def extra_container_html_options
          {
            target: '_blank',
            rel: 'noopener noreferrer',
            class: 'shortcuts-external_wiki'
          }
        end

        override :title
        def title
          s_('ExternalWikiService|External wiki')
        end

        override :sprite_icon
        def sprite_icon
          'external-link'
        end

        override :render?
        def render?
          external_wiki.present?
        end

        override :serialize_as_menu_item_args
        def serialize_as_menu_item_args
          super.merge({
            item_id: :external_wiki,
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::PlanMenu
          })
        end

        private

        def external_wiki
          @external_wiki ||= context.project.external_wiki
        end
      end
    end
  end
end
