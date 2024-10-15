# frozen_string_literal: true

module Users
  class RecordLastActivityWorker
    include Gitlab::EventStore::Subscriber

    data_consistency :delayed
    feature_category :seat_cost_management
    urgency :low
    idempotent!
    deduplicate :until_executed

    def handle_event(_event); end
  end
end
