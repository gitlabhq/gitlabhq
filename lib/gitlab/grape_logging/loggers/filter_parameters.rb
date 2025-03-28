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

          settings[:log_safety][:safe].each do |key|
            loggable_params[key] = request.params[key] if loggable_params.key?(key)
          end

          settings[:log_safety][:unsafe].each do |key|
            loggable_params[key] = @replacement if loggable_params.key?(key)
          end

          loggable_params
        end
      end
    end
  end
end
