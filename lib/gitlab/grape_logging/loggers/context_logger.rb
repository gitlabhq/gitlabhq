# frozen_string_literal: true

# This module adds additional correlation id the grape logger
module Gitlab
  module GrapeLogging
    module Loggers
      class ContextLogger < ::GrapeLogging::Loggers::Base
        def parameters(_, _)
          Gitlab::ApplicationContext.current
        end
      end
    end
  end
end
