module EE
  module GeoHelper
    def node_status_icon(node)
      unless node.primary?
        status = node.enabled? ? 'unknown' : 'disabled'
        icon = status == 'healthy' ? 'check' : 'times'

        icon "#{icon} fw",
             class: "js-geo-node-icon geo-node-#{status}",
             title: status.capitalize
      end
    end

    def status_loading_icon
      icon "spinner spin fw", class: 'js-geo-node-loading'
    end

    def node_class(node)
      klass = []
      klass << 'js-geo-secondary-node' if node.secondary?
      klass << 'node-disabled' unless node.enabled?
      klass
    end

    def toggle_node_button(node)
      btn_class, title, data =
        if node.enabled?
          ['warning', 'Disable', { confirm: 'Disabling a node stops the sync process. Are you sure?' }]
        else
          %w[success Enable]
        end

      link_to title,
              toggle_admin_geo_node_path(node),
              method: :post,
              class: "btn btn-sm btn-#{btn_class}",
              title: title,
              data: data
    end
  end
end
