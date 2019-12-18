# frozen_string_literal: true

module Prometheus
  class ProxyVariableSubstitutionService < BaseService
    include Stepable

    steps :validate_variables,
      :add_params_to_result,
      :substitute_ruby_variables,
      :substitute_liquid_variables

    def initialize(environment, params = {})
      @environment, @params = environment, params.deep_dup
    end

    def execute
      execute_steps
    end

    private

    def validate_variables(_result)
      return success unless variables

      unless variables.is_a?(Array) && variables.size.even?
        return error(_('Optional parameter "variables" must be an array of keys and values. Ex: [key1, value1, key2, value2]'))
      end

      success
    end

    def add_params_to_result(result)
      result[:params] = params

      success(result)
    end

    def substitute_liquid_variables(result)
      return success(result) unless query(result)

      result[:params][:query] =
        TemplateEngines::LiquidService.new(query(result)).render(full_context)

      success(result)
    rescue TemplateEngines::LiquidService::RenderError => e
      error(e.message)
    end

    def substitute_ruby_variables(result)
      return success(result) unless query(result)

      # The % operator doesn't replace variables if the hash contains string
      # keys.
      result[:params][:query] = query(result) % predefined_context.symbolize_keys

      success(result)
    rescue TypeError, ArgumentError => exception
      log_error(exception.message)
      Gitlab::ErrorTracking.track_exception(exception, {
        template_string: query(result),
        variables: predefined_context
      })

      error(_('Malformed string'))
    end

    def predefined_context
      @predefined_context ||= Gitlab::Prometheus::QueryVariables.call(@environment)
    end

    def full_context
      @full_context ||= predefined_context.reverse_merge(variables_hash)
    end

    def variables
      params[:variables]
    end

    def variables_hash
      # .each_slice(2) converts ['key1', 'value1', 'key2', 'value2'] into
      # [['key1', 'value1'], ['key2', 'value2']] which is then converted into
      # a hash by to_h: {'key1' => 'value1', 'key2' => 'value2'}
      # to_h will raise an ArgumentError if the number of elements in the original
      # array is not even.
      variables&.each_slice(2).to_h
    end

    def query(result)
      result[:params][:query]
    end
  end
end
