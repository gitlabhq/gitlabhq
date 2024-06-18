# frozen_string_literal: true

# This grape_logging module (https://github.com/aserafin/grape_logging) makes it
# possible to log how much time an API request was queued by Workhorse.
module Gitlab
  module GrapeLogging
    module Loggers
      class QueueDurationLogger < ::GrapeLogging::Loggers::Base
        def parameters(request, _)
          duration_s = request.env[Gitlab::Middleware::RailsQueueDuration::GITLAB_RAILS_QUEUE_DURATION_KEY].presence

          return {} unless duration_s

          { queue_duration_s: duration_s }
        end
      end
    end
  end
end
