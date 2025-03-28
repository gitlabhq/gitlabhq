# frozen_string_literal: true

module Issuable
  class CreateReminderWorker
    include ApplicationWorker

    data_consistency :delayed

    idempotent!
    feature_category :code_review_workflow

    def perform(target_id, target_type, user_id); end
  end
end
