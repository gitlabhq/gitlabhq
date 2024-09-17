# frozen_string_literal: true

module Abuse
  class SpamAbuseEventsWorker
    include ApplicationWorker

    data_consistency :delayed

    idempotent!
    feature_category :instance_resiliency
    urgency :low

    def perform(params)
      AntiAbuse::SpamAbuseEventsWorker.new.perform(params)
    end
  end
end
