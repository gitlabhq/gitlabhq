# frozen_string_literal: true

module Users
  class RecordLastActivityWorker
    include Gitlab::EventStore::Subscriber

    data_consistency :delayed
    feature_category :seat_cost_management
    urgency :low
    idempotent!
    deduplicate :until_executed

    def handle_event(event)
      user = User.find_by_id(event.data[:user_id])
      namespace = Namespace.find_by_id(event.data[:namespace_id])

      return unless user && namespace

      Members::ActivityService.new(user, namespace).execute
    end
  end
end
