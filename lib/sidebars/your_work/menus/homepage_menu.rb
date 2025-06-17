# frozen_string_literal: true

module Sidebars # rubocop:disable Gitlab/BoundedContexts -- This has to be named this way.
  module YourWork
    module Menus
      class HomepageMenu < ::Sidebars::Menu
        override :link
        def link
          root_path
        end

        override :title
        def title
          _('Home')
        end

        override :sprite_icon
        def sprite_icon
          'home'
        end

        override :render?
        def render?
          !!context.current_user && Feature.enabled?(:personal_homepage, context.current_user)
        end

        override :active_routes
        def active_routes
          { controller: ['root'] }
        end
      end
    end
  end
end
