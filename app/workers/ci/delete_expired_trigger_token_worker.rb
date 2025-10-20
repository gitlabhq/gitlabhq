# frozen_string_literal: true

module Ci
  class DeleteExpiredTriggerTokenWorker
    include ApplicationWorker

    data_consistency :sticky
    feature_category :continuous_integration
    queue_namespace :cronjob
    idempotent!

    BATCH_SIZE = 100

    def perform
      ::Ci::Trigger.ready_for_deletion.each_batch(of: BATCH_SIZE) do |relation|
        relation.delete_all
      end
    end
  end
end
