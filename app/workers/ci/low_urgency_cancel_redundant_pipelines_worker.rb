# frozen_string_literal: true

module Ci
  # Scheduled pipelines rarely cancel other pipelines and we don't need to
  # use high urgency
  class LowUrgencyCancelRedundantPipelinesWorker < CancelRedundantPipelinesWorker
    urgency :low
    idempotent!
  end
end
