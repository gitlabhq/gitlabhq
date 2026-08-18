# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- This has to be named this way.
module Sidebars
  module Projects
    module SuperSidebarMenus
      class ObserveMenu < ::Sidebars::Menu
        override :title
        def title
          s_('Navigation|Observe')
        end

        override :sprite_icon
        def sprite_icon
          'eye'
        end

        override :configure_menu_items
        def configure_menu_items
          [
            :logs_explorer,
            :traces_explorer,
            :metrics_explorer,
            :infrastructure_monitoring,
            :services,
            :observability_dashboard,
            :observability_alerts,
            :exceptions,
            :service_map,
            :messaging_queues,
            :api_monitoring,
            :notification_channels,
            :api_keys,
            :setup
          ].each { |id| add_item(::Sidebars::NilMenuItem.new(item_id: id)) }
        end
      end
    end
  end
end
# rubocop:enable Gitlab/BoundedContexts
