# frozen_string_literal: true

module ServiceDesk
  # Marks custom email verifications as failed when
  # verification has started and timeframe to ingest
  # the verification email has closed.
  #
  # This ensures we can finish the verification process and send verification result emails
  # even when we did not receive any verification email.
  class CustomEmailVerificationCleanupWorker
    include ApplicationWorker
    include CronjobQueue

    idempotent!

    data_consistency :sticky
    feature_category :service_desk

    def perform
      # Limit ensures we have 50ms per verification before another job gets scheduled.
      collection = CustomEmailVerification.started.overdue.limit(2_400)

      collection.find_each do |verification|
        with_context(project: verification.project) do
          CustomEmailVerifications::UpdateService.new(
            project: verification.project,
            current_user: nil,
            params: {
              mail: nil
            }
          ).execute
        end
      end
    end
  end
end
