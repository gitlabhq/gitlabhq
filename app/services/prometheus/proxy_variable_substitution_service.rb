# frozen_string_literal: true

module Prometheus
  class ProxyVariableSubstitutionService < BaseService
    include Stepable

    VARIABLE_INTERPOLATION_REGEX = /
      {{                  # Variable needs to be wrapped in these chars.
        \s*               # Allow whitespace before and after the variable name.
          (?<variable>    # Named capture.
            \w+           # Match one or more word characters.
          )
        \s*
      }}
    /x.freeze

    steps :validate_variables,
      :add_params_to_result,
      :substitute_params,
      :substitute_variables

    def initialize(environment, params = {})
      @environment, @params = environment, params.deep_dup
    end

    def execute
      execute_steps
    end

    private

    def validate_variables(_result)
      return success unless variables

      unless variables.is_a?(ActionController::Parameters)
        return error(_('Optional parameter "variables" must be a Hash. Ex: variables[key1]=value1'))
      end

      success
    end

    def add_params_to_result(result)
      result[:params] = params

      success(result)
    end

    def substitute_params(result)
      start_time = result[:params][:start_time]
      end_time = result[:params][:end_time]

      result[:params][:start] = start_time if start_time
      result[:params][:end]   = end_time if end_time

      success(result)
    end

    def substitute_variables(result)
      return success(result) unless query(result)

      result[:params][:query] = gsub(query(result), full_context(result))

      success(result)
    end

    def gsub(string, context)
      # Search for variables of the form `{{variable}}` in the string and replace
      # them with their value.
      string.gsub(VARIABLE_INTERPOLATION_REGEX) do |match|
        # Replace with the value of the variable, or if there is no such variable,
        # replace the invalid variable with itself. So,
        # `up{instance="{{invalid_variable}}"}` will remain
        # `up{instance="{{invalid_variable}}"}` after substitution.
        context.fetch($~[:variable], match)
      end
    end

    def predefined_context(result)
      Gitlab::Prometheus::QueryVariables.call(
        @environment,
        start_time: start_timestamp(result),
        end_time: end_timestamp(result)
      ).stringify_keys
    end

    def full_context(result)
      @full_context ||= predefined_context(result).reverse_merge(variables_hash)
    end

    def variables
      params[:variables]
    end

    def variables_hash
      variables.to_h
    end

    def start_timestamp(result)
      Time.rfc3339(result[:params][:start])
    rescue ArgumentError
    end

    def end_timestamp(result)
      Time.rfc3339(result[:params][:end])
    rescue ArgumentError
    end

    def query(result)
      result[:params][:query]
    end
  end
end
