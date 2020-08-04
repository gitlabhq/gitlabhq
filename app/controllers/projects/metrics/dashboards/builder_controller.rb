# frozen_string_literal: true

module Projects
  module Metrics
    module Dashboards
      class BuilderController < Projects::ApplicationController
        before_action :ensure_feature_flags
        before_action :authorize_metrics_dashboard!

        def panel_preview
          respond_to do |format|
            format.json { render json: render_panel }
          end
        end

        private

        def ensure_feature_flags
          render_404 unless Feature.enabled?(:metrics_dashboard_new_panel_page, project)
        end

        def render_panel
          {
            "title": "Memory Usage (Total)",
            "type": "area-chart",
            "y_label": "Total Memory Used (GB)",
            "weight": 4,
            "metrics": [
              {
                "id": "system_metrics_kubernetes_container_memory_total",
                "query_range": "avg(sum(container_memory_usage_bytes{container_name!=\"POD\",pod_name=~\"^{{ci_environment_slug}}-(.*)\",namespace=\"{{kube_namespace}}\"}) by (job)) without (job)  /1024/1024/1024",
                "label": "Total (GB)",
                "unit": "GB",
                "metric_id": 15,
                "edit_path": nil,
                "prometheus_endpoint_path": "/root/autodevops-deploy/-/environments/29/prometheus/api/v1/query_range?query=avg%28sum%28container_memory_usage_bytes%7Bcontainer_name%21%3D%22POD%22%2Cpod_name%3D~%22%5E%7B%7Bci_environment_slug%7D%7D-%28.%2A%29%22%2Cnamespace%3D%22%7B%7Bkube_namespace%7D%7D%22%7D%29+by+%28job%29%29+without+%28job%29++%2F1024%2F1024%2F1024"
              }
            ],
            "id": "4570deed516d0bf93fb42879004117009ab456ced27393ec8dce5b6960438132"
          }
        end
      end
    end
  end
end
