# frozen_string_literal: true

# This module adds additional performance metrics to the grape logger
module Gitlab
  module GrapeLogging
    module Loggers
      class PerfLogger < ::GrapeLogging::Loggers::Base
        include ::Gitlab::InstrumentationHelper

        def parameters(_, _)
          payload = {}
          payload.tap { add_instrumentation_data(payload) }
        end
      end
    end
  end
end
