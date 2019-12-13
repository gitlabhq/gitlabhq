# frozen_string_literal: true

module Prometheus
  class ProxyVariableSubstitutionService < BaseService
    include Stepable

    steps :add_params_to_result, :substitute_ruby_variables

    def initialize(environment, params = {})
      @environment, @params = environment, params.deep_dup
    end

    def execute
      execute_steps
    end

    private

    def add_params_to_result(result)
      result[:params] = params

      success(result)
    end

    def substitute_ruby_variables(result)
      return success(result) unless query

      # The % operator doesn't replace variables if the hash contains string
      # keys.
      result[:params][:query] = query % predefined_context.symbolize_keys

      success(result)
    rescue TypeError, ArgumentError => exception
      log_error(exception.message)
      Gitlab::Sentry.track_exception(exception, extra: {
        template_string: query,
        variables: predefined_context
      })

      error(_('Malformed string'))
    end

    def predefined_context
      @predefined_context ||= Gitlab::Prometheus::QueryVariables.call(@environment)
    end

    def query
      params[:query]
    end
  end
end
