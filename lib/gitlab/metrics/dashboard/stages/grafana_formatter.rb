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
            InputFormatValidator.new(
              grafana_dashboard,
              datasource,
              panel,
              query_params
            ).validate!

            new_dashboard = formatted_dashboard

            dashboard.clear
            dashboard.merge!(new_dashboard)
          end

          private

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
                panel[:id].to_s == query_params[:panelId]
              end
            end
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
            expression = replace_global_variables(expression, metric)

            expression
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
            expression = expression.gsub('$__to', query_params[:to])

            expression
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

        class InputFormatValidator
          include ::Gitlab::Metrics::Dashboard::Errors

          attr_reader :grafana_dashboard, :datasource, :panel, :query_params

          UNSUPPORTED_GRAFANA_GLOBAL_VARS = %w(
            $__interval_ms
            $__timeFilter
            $__name
            $timeFilter
            $interval
          ).freeze

          def initialize(grafana_dashboard, datasource, panel, query_params)
            @grafana_dashboard = grafana_dashboard
            @datasource = datasource
            @panel = panel
            @query_params = query_params
          end

          def validate!
            validate_query_params!
            validate_datasource!
            validate_panel_type!
            validate_variable_definitions!
            validate_global_variables!
          end

          private

          def validate_datasource!
            return if datasource[:access] == 'proxy' && datasource[:type] == 'prometheus'

            raise_error 'Only Prometheus datasources with proxy access in Grafana are supported.'
          end

          def validate_query_params!
            return if [:panelId, :from, :to].all? { |param| query_params.include?(param) }

            raise_error 'Grafana query parameters must include panelId, from, and to.'
          end

          def validate_panel_type!
            return if panel[:type] == 'graph' && panel[:lines]

            raise_error 'Panel type must be a line graph.'
          end

          def validate_variable_definitions!
            return unless grafana_dashboard[:dashboard][:templating]

            return if grafana_dashboard[:dashboard][:templating][:list].all? do |variable|
              query_params[:"var-#{variable[:name]}"].present?
            end

            raise_error 'All Grafana variables must be defined in the query parameters.'
          end

          def validate_global_variables!
            return unless panel_contains_unsupported_vars?

            raise_error 'Prometheus must not include'
          end

          def panel_contains_unsupported_vars?
            panel[:targets].any? do |target|
              UNSUPPORTED_GRAFANA_GLOBAL_VARS.any? do |variable|
                target[:expr].include?(variable)
              end
            end
          end

          def raise_error(message)
            raise DashboardProcessingError.new(message)
          end
        end
      end
    end
  end
end
