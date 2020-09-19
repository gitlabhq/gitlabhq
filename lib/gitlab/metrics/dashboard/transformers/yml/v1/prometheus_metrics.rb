# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Transformers
        module Yml
          module V1
            # Takes a JSON schema validated dashboard hash and
            # maps it to PrometheusMetric model attributes
            class PrometheusMetrics
              def initialize(dashboard_hash, project: nil, dashboard_path: nil)
                @dashboard_hash = dashboard_hash.with_indifferent_access
                @project = project
                @dashboard_path = dashboard_path

                @dashboard_hash.default_proc = -> (h, k) { raise Transformers::Errors::MissingAttribute, k.to_s }
              end

              def execute
                prometheus_metrics = []

                dashboard_hash[:panel_groups].each do |panel_group|
                  panel_group[:panels].each do |panel|
                    panel[:metrics].each do |metric|
                      prometheus_metrics << {
                        project:        project,
                        title:          panel[:title],
                        y_label:        panel[:y_label],
                        query:          metric[:query_range] || metric[:query],
                        unit:           metric[:unit],
                        legend:         metric[:label],
                        identifier:     metric[:id],
                        group:          Enums::PrometheusMetric.groups[:custom],
                        common:         false,
                        dashboard_path: dashboard_path
                      }.compact
                    end
                  end
                end

                prometheus_metrics
              end

              private

              attr_reader :dashboard_hash, :project, :dashboard_path
            end
          end
        end
      end
    end
  end
end
