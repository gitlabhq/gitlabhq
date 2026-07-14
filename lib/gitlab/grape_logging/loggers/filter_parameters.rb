# frozen_string_literal: true

module Gitlab
  module GrapeLogging
    module Loggers
      # In the CI variables APIs, the POST or PUT parameters will always be
      # literally 'key' and 'value'. Rails' default filters_parameters will
      # always incorrectly mask the value of param 'key' when it should mask the
      # value of the param 'value'.
      # See: https://gitlab.com/gitlab-org/gitlab/-/issues/353857
      class FilterParameters < ::GrapeLogging::Loggers::FilterParameters
        private

        def safe_parameters(request)
          loggable_params = super
          settings = request.env[Grape::Env::API_ENDPOINT]&.route&.settings

          return loggable_params unless settings&.key?(:log_safety)

          apply_safe_overrides(loggable_params, request.params, settings[:log_safety][:safe])
          apply_unsafe_replacements(loggable_params, settings[:log_safety][:unsafe])
          apply_unsafe_nested_replacements(loggable_params, settings[:log_safety][:unsafe_nested])

          loggable_params
        end

        def apply_safe_overrides(loggable_params, request_params, keys)
          Array(keys).each do |key|
            loggable_params[key] = request_params[key] if loggable_params.key?(key)
          end
        end

        def apply_unsafe_replacements(loggable_params, keys)
          Array(keys).each do |key|
            loggable_params[key] = @replacement if loggable_params.key?(key)
          end
        end

        def apply_unsafe_nested_replacements(loggable_params, pairs)
          Array(pairs).each do |parent_key, nested_key|
            next unless loggable_params[parent_key].is_a?(Array)

            loggable_params[parent_key] = loggable_params[parent_key].map do |item|
              item.is_a?(Hash) && item.key?(nested_key) ? item.merge(nested_key => @replacement) : item
            end
          end
        end
      end
    end
  end
end
