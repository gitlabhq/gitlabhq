# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- This has to be named this way.
module Sidebars
  module Groups
    module SuperSidebarMenus
      class ObservabilityMenu < ::Sidebars::Menu
        override :title
        def title
          s_('Navigation|Observability')
        end

        override :sprite_icon
        def sprite_icon
          'eye'
        end

        override :configure_menu_items
        def configure_menu_items
          [
            :services,
            :traces_explorer,
            :logs_explorer,
            :metrics_explorer,
            :infrastructure_monitoring,
            :dashboard,
            :messaging_queues,
            :api_monitoring,
            :alerts,
            :exceptions,
            :service_map,
            :settings
          ].each { |id| add_item(::Sidebars::NilMenuItem.new(item_id: id)) }
        end
      end
    end
  end
end
# rubocop:enable Gitlab/BoundedContexts
