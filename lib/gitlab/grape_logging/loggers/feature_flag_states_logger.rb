# frozen_string_literal: true

module Gitlab
  module GrapeLogging
    module Loggers
      class FeatureFlagStatesLogger < ::GrapeLogging::Loggers::Base
        def parameters(_, _)
          return {} unless Feature.enabled?(:feature_flag_state_logs, :current_request)

          formatted = Feature.logged_states_for_log
          return {} if formatted.empty?

          { feature_flag_states: formatted }
        end
      end
    end
  end
end
