# frozen_string_literal: true

module Sidebars
  module Groups
    module Menus
      class ObservabilityMenu < ::Sidebars::Menu
        override :link
        def link
          group_observability_index_path(context.group)
        end

        override :title
        def title
          _('Observability')
        end

        override :sprite_icon
        def sprite_icon
          'monitor'
        end

        override :render?
        def render?
          can?(context.current_user, :read_observability, context.group)
        end

        override :active_routes
        def active_routes
          { controller: :observability, path: 'groups#observability' }
        end
      end
    end
  end
end
