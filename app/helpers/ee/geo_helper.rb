module EE
  module GeoHelper
    def node_status_icon(node)
      unless node.primary?
        status = node.enabled? ? 'healthy' : 'disabled'

        if status == 'healthy'
          icon = 'check'
        else
          icon = 'times'
        end

        icon "#{icon} fw",
             class: "js-geo-node-icon geo-node-#{status}",
             title: status.capitalize
      end
    end

    def node_class(node)
      klass = []
      klass << 'js-geo-secondary-node' if node.secondary?
      klass << ' node-disabled' unless node.enabled?
      klass
    end

    def toggle_node_button(node)
      btn_class, title, data =
        if node.enabled?
          ['warning', 'Disable', { confirm: 'Disabling a node stops the sync process. Are you sure?' }]
        else
          ['success', 'Enable']
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
