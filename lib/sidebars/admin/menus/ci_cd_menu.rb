# frozen_string_literal: true

module Sidebars
  module Admin
    module Menus
      class CiCdMenu < ::Sidebars::Admin::BaseMenu
        override :configure_menu_items
        def configure_menu_items
          add_item(runners_menu_item)
          add_item(jobs_menu_item)

          true
        end

        override :title
        def title
          s_('Admin|CI/CD')
        end

        override :sprite_icon
        def sprite_icon
          'rocket'
        end

        private

        def runners_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Runners'),
            link: admin_runners_path,
            active_routes: { controller: 'runners' },
            item_id: :runners
          )
        end

        def jobs_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Jobs'),
            link: admin_jobs_path,
            active_routes: { controller: 'jobs' },
            item_id: :jobs
          )
        end
      end
    end
  end
end

Sidebars::Admin::Menus::CiCdMenu.prepend_mod
