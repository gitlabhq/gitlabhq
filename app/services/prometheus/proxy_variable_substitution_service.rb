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

    # @param environment [Environment]
    # @param params [Hash<Symbol,Any>]
    # @param params - query [String] The Prometheus query string.
    # @param params - start [String] (optional) A time string in the rfc3339 format.
    # @param params - start_time [String] (optional) A time string in the rfc3339 format.
    # @param params - end [String] (optional) A time string in the rfc3339 format.
    # @param params - end_time [String] (optional) A time string in the rfc3339 format.
    # @param params - variables [ActionController::Parameters] (optional) Variables with their values.
    #     The keys in the Hash should be the name of the variable. The value should be the value of the
    #     variable. Ex: `ActionController::Parameters.new(variable1: 'value 1', variable2: 'value 2').permit!`
    # @return [Prometheus::ProxyVariableSubstitutionService]
    #
    # Example:
    #      Prometheus::ProxyVariableSubstitutionService.new(environment, {
    #        params: {
    #          start_time: '2020-07-03T06:08:36Z',
    #          end_time: '2020-07-03T14:08:52Z',
    #          query: 'up{instance="{{instance}}"}',
    #          variables: { instance: 'srv1' }
    #        }
    #      })
    def initialize(environment, params = {})
      @environment = environment
      @params = params.deep_dup
    end

    # @return - params [Hash<Symbol,Any>] Returns a Hash containing a params key which is
    #   similar to the `params` that is passed to the initialize method with 2 differences:
    #     1. Variables in the query string are substituted with their values.
    #        If a variable present in the query string has no known value (values
    #        are obtained from the `variables` Hash in `params` or from
    #        `Gitlab::Prometheus::QueryVariables.call`), it will not be substituted.
    #     2. `start` and `end` keys are added, with their values copied from `start_time`
    #        and `end_time`.
    #
    # Example output:
    #
    # {
    #   params: {
    #     start_time: '2020-07-03T06:08:36Z',
    #     start: '2020-07-03T06:08:36Z',
    #     end_time: '2020-07-03T14:08:52Z',
    #     end: '2020-07-03T14:08:52Z',
    #     query: 'up{instance="srv1"}',
    #     variables: { instance: 'srv1' }
    #   }
    # }
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
