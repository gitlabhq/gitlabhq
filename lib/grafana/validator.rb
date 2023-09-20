# frozen_string_literal: true

# Performs checks on whether resources from Grafana can be handled
# We have certain restrictions on which formats we accept.
# Some are technical requirements, others are simplifications.
module Grafana
  class Validator
    Error = Class.new(StandardError)

    attr_reader :grafana_dashboard, :datasource, :panel, :query_params

    UNSUPPORTED_GRAFANA_GLOBAL_VARS = %w[
      $__interval_ms
      $__timeFilter
      $__name
      $timeFilter
      $interval
    ].freeze

    def initialize(grafana_dashboard, datasource, panel, query_params)
      @grafana_dashboard = grafana_dashboard
      @datasource = datasource
      @panel = panel
      @query_params = query_params
    end

    def validate!
      validate_query_params!
      validate_panel_type!
      validate_variable_definitions!
      validate_global_variables!
      validate_datasource! if datasource
    end

    def valid?
      validate!

      true
    rescue ::Grafana::Validator::Error
      false
    end

    private

    def validate_query_params!
      return if [:from, :to].all? { |param| query_params.include?(param) }

      raise_error 'Grafana query parameters must include from and to.'
    end

    # We may choose to support other panel types in future.
    def validate_panel_type!
      return if panel && panel[:type] == 'graph' && panel[:lines]

      raise_error 'Panel type must be a line graph.'
    end

    # We must require variable definitions to create valid prometheus queries.
    def validate_variable_definitions!
      return unless grafana_dashboard[:dashboard][:templating]

      return if grafana_dashboard[:dashboard][:templating][:list].all? do |variable|
        query_params[:"var-#{variable[:name]}"].present?
      end

      raise_error 'All Grafana variables must be defined in the query parameters.'
    end

    # We may choose to support further Grafana variables in future.
    def validate_global_variables!
      return unless panel_contains_unsupported_vars?

      raise_error "Prometheus must not include #{UNSUPPORTED_GRAFANA_GLOBAL_VARS}"
    end

    # We may choose to support additional datasources in future.
    def validate_datasource!
      return if datasource[:access] == 'proxy' && datasource[:type] == 'prometheus'

      raise_error 'Only Prometheus datasources with proxy access in Grafana are supported.'
    end

    def panel_contains_unsupported_vars?
      panel[:targets].any? do |target|
        UNSUPPORTED_GRAFANA_GLOBAL_VARS.any? do |variable|
          target[:expr].include?(variable)
        end
      end
    end

    def raise_error(message)
      raise Validator::Error, message
    end
  end
end
