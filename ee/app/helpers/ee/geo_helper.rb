# frozen_string_literal: true

module EE
  module GeoHelper
    STATUS_ICON_NAMES_BY_STATE = {
        synced: 'check',
        pending: 'clock-o',
        failed: 'exclamation-triangle',
        never: 'circle-o'
    }.freeze

    def node_vue_list_properties
      version, revision =
        if ::Gitlab::Geo.primary?
          [::Gitlab::VERSION, ::Gitlab.revision]
        else
          status = ::Gitlab::Geo.primary_node&.status

          [status&.version, status&.revision]
        end

      {
        primary_version: version.to_s,
        primary_revision: revision.to_s,
        node_actions_allowed: ::Gitlab::Database.db_read_write?.to_s,
        node_edit_allowed: ::Gitlab::Geo.license_allows?.to_s
      }
    end

    def node_namespaces_options(namespaces)
      namespaces.map { |g| { id: g.id, text: g.full_name } }
    end

    def node_selected_namespaces_to_replicate(node)
      node.namespaces.map(&:human_name).sort.join(', ')
    end

    def node_status_icon(node)
      unless node.primary?
        status = node.enabled? ? 'unknown' : 'disabled'
        icon = status == 'healthy' ? 'check' : 'times'

        icon "#{icon} fw",
             class: "js-geo-node-icon geo-node-#{status}",
             title: status.capitalize
      end
    end

    def selective_sync_type_options_for_select(geo_node)
      options_for_select(
        [
          [s_('Geo|All projects'), ''],
          [s_('Geo|Projects in certain groups'), 'namespaces'],
          [s_('Geo|Projects in certain storage shards'), 'shards']
        ],
        geo_node.selective_sync_type
      )
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

    def project_registry_status(project_registry)
      status_type = case project_registry.synchronization_state
                    when :failed then
                      'status-type-failure'
                    when :synced then
                      'status-type-success'
                    end

      content_tag(:div, class: "project-status-content #{status_type}") do
        icon = project_registry_status_icon(project_registry)
        text = project_registry_status_text(project_registry)

        [icon, text].join(' ').html_safe
      end
    end

    def project_registry_status_icon(project_registry)
      icon(STATUS_ICON_NAMES_BY_STATE.fetch(project_registry.synchronization_state, 'exclamation-triangle'))
    end

    def project_registry_status_text(project_registry)
      case project_registry.synchronization_state
      when :never
        s_('Geo|Not synced yet')
      when :failed
        s_('Geo|Failed')
      when :pending
        if project_registry.pending_synchronization?
          s_('Geo|Pending synchronization')
        elsif project_registry.pending_verification?
          s_('Geo|Pending verification')
        else
          # should never reach this state, unless we introduce new behavior
          s_('Geo|Unknown state')
        end
      when :synced
        s_('Geo|In sync')
      else
        # should never reach this state, unless we introduce new behavior
        s_('Geo|Unknown state')
      end
    end
  end
end
