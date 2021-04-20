# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Stages
        class GrafanaFormatter < BaseStage
          include Gitlab::Utils::StrongMemoize

          CHART_TYPE = 'area-chart'
          PROXY_PATH = 'api/v1/query_range'

          # Reformats the specified panel in the Gitlab
          # dashboard-yml format
          def transform!
            validate_input!

            new_dashboard = formatted_dashboard

            dashboard.clear
            dashboard.merge!(new_dashboard)
          end

          private

          def validate_input!
            ::Grafana::Validator.new(
              grafana_dashboard,
              datasource,
              panel,
              query_params
            ).validate!
          rescue ::Grafana::Validator::Error => e
            raise ::Gitlab::Metrics::Dashboard::Errors::DashboardProcessingError, e.message
          end

          def formatted_dashboard
            { panel_groups: [{ panels: [formatted_panel] }] }
          end

          def formatted_panel
            {
              title:   panel[:title],
              type:    CHART_TYPE,
              y_label: '', # Grafana panels do not include a Y-Axis label
              metrics: panel[:targets].map.with_index do |target, idx|
                formatted_metric(target, idx)
              end
            }
          end

          def formatted_metric(metric, idx)
            {
              id:                       "#{metric[:legendFormat]}_#{idx}",
              query_range:              format_query(metric),
              label:                    replace_variables(metric[:legendFormat]),
              prometheus_endpoint_path: prometheus_endpoint_for_metric(metric)
            }.compact
          end

          # Panel specified by the url from the Grafana dashboard
          def panel
            strong_memoize(:panel) do
              grafana_dashboard[:dashboard][:panels].find do |panel|
                query_params[:panelId] ? matching_panel?(panel) : valid_panel?(panel)
              end
            end
          end

          # Determines whether a given panel is the one
          # specified by the linked grafana url
          def matching_panel?(panel)
            panel[:id].to_s == query_params[:panelId]
          end

          # Determines whether any given panel has the potenial
          # to return valid results from grafana/prometheus
          def valid_panel?(panel)
            ::Grafana::Validator
              .new(grafana_dashboard, datasource, panel, query_params)
              .valid?
          end

          # Grafana url query parameters. Includes information
          # on which panel to select and time range.
          def query_params
            strong_memoize(:query_params) do
              Gitlab::Metrics::Dashboard::Url.parse_query(grafana_url)
            end
          end

          # Endpoint which will return prometheus metric data
          # for the metric
          def prometheus_endpoint_for_metric(metric)
            Gitlab::Routing.url_helpers.project_grafana_api_path(
              project,
              datasource_id: datasource[:id],
              proxy_path: PROXY_PATH,
              query: format_query(metric)
            )
          end

          # Reformats query for compatibility with prometheus api.
          def format_query(metric)
            expression = remove_new_lines(metric[:expr])
            expression = replace_variables(expression)
            replace_global_variables(expression, metric)
          end

          # Accomodates instance-defined Grafana variables.
          # These are variables defined by users, and values
          # must be provided in the query parameters.
          def replace_variables(expression)
            return expression unless grafana_dashboard[:dashboard][:templating]

            grafana_dashboard[:dashboard][:templating][:list]
              .sort_by { |variable| variable[:name].length }
              .each do |variable|
                variable_value = query_params[:"var-#{variable[:name]}"]

                expression = expression.gsub("$#{variable[:name]}", variable_value)
                expression = expression.gsub("[[#{variable[:name]}]]", variable_value)
                expression = expression.gsub("{{#{variable[:name]}}}", variable_value)
              end

            expression
          end

          # Replaces Grafana global built-in variables with values.
          # Only $__interval and $__from and $__to are supported.
          #
          # See https://grafana.com/docs/reference/templating/#global-built-in-variables
          def replace_global_variables(expression, metric)
            expression = expression.gsub('$__interval', metric[:interval]) if metric[:interval]
            expression = expression.gsub('$__from', query_params[:from])
            expression.gsub('$__to', query_params[:to])
          end

          # Removes new lines from expression.
          def remove_new_lines(expression)
            expression.gsub(/\R+/, '')
          end

          # Grafana datasource object corresponding to the
          # specified dashboard
          def datasource
            params[:datasource]
          end

          # The specified Grafana dashboard
          def grafana_dashboard
            params[:grafana_dashboard]
          end

          # The URL specifying which Grafana panel to embed
          def grafana_url
            params[:grafana_url]
          end
        end
      end
    end
  end
end
