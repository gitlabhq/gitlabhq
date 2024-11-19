# frozen_string_literal: true

module Ci
  module JobToken
    class LogAuthorizationWorker
      include ApplicationWorker

      feature_category :secrets_management

      urgency :low
      data_consistency :always
      idempotent!
      deduplicate :until_executed, including_scheduled: true, if_deduplicated: :reschedule_once

      def perform(accessed_project_id, origin_project_id)
        Ci::JobToken::Authorization.log_captures!(
          accessed_project_id: accessed_project_id,
          origin_project_id: origin_project_id
        )
      end
    end
  end
end
