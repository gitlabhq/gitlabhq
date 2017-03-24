module EE
  module GeoHelper
    def node_status_icon(node)
      if node.primary?
        icon 'star fw', class: 'has-tooltip', title: 'Primary node'
      else
        status = node.enabled? ? 'healthy' : 'disabled'

        icon 'globe fw',
             class: "js-geo-node-icon geo-node-icon-#{status} has-tooltip",
             title: status.capitalize
      end
    end

    def toggle_node_button(node)
      btn_class, title, data =
        if node.enabled?
          ['warning', 'Disable node', { confirm: 'Disabling a node stops the sync process. Are you sure?' }]
        else
          ['success', 'Enable node']
        end

      link_to icon('power-off fw', text: title),
              toggle_admin_geo_node_path(node),
              method: :post,
              class: "btn btn-sm btn-#{btn_class} prepend-left-10 has-tooltip",
              title: title,
              data: data
    end
  end
end
