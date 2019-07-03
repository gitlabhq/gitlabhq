# frozen_string_literal: true

module Gitlab
  module Importers
    module CommonMetrics
      module PrometheusMetricEnums
        def self.groups
          {
            # built-in groups
            nginx_ingress_vts: -1,
            ha_proxy: -2,
            aws_elb: -3,
            nginx: -4,
            kubernetes: -5,
            nginx_ingress: -6,

            # custom groups
            business: 0,
            response: 1,
            system: 2
          }
        end

        def self.group_titles
          {
            business: _('Business metrics (Custom)'),
            response: _('Response metrics (Custom)'),
            system: _('System metrics (Custom)'),
            nginx_ingress_vts: _('Response metrics (NGINX Ingress VTS)'),
            nginx_ingress: _('Response metrics (NGINX Ingress)'),
            ha_proxy: _('Response metrics (HA Proxy)'),
            aws_elb: _('Response metrics (AWS ELB)'),
            nginx: _('Response metrics (NGINX)'),
            kubernetes: _('System metrics (Kubernetes)')
          }
        end
      end
    end
  end
end

::Gitlab::Importers::CommonMetrics::PrometheusMetricEnums.prepend EE::Gitlab::Importers::CommonMetrics::PrometheusMetricEnums
