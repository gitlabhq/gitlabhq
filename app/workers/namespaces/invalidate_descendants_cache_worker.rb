# frozen_string_literal: true

module Namespaces
  class InvalidateDescendantsCacheWorker
    include Gitlab::EventStore::Subscriber

    data_consistency :always
    feature_category :groups_and_projects
    idempotent!

    def handle_event(event)
      Namespaces::Descendants.expire_for([event.data[:namespace_id]])
    end
  end
end
