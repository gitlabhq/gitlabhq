# frozen_string_literal: true

# This module adds additional correlation id the grape logger
module Gitlab
  module GrapeLogging
    module Loggers
      class CorrelationIdLogger < ::GrapeLogging::Loggers::Base
        def parameters(_, _)
          { Labkit::Fields::CORRELATION_ID => Labkit::Correlation::CorrelationId.current_id }
        end
      end
    end
  end
end
