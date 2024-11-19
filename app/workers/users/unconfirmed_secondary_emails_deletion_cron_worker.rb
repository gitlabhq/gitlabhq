# frozen_string_literal: true

module Users
  class UnconfirmedSecondaryEmailsDeletionCronWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- This worker does not perform work scoped to a context

    deduplicate :until_executed
    idempotent!
    data_consistency :always
    feature_category :user_management

    BATCH_SIZE = 1000

    def perform
      loop do
        records_deleted = Email.unconfirmed_and_created_before(created_cut_off).limit(BATCH_SIZE).delete_all

        break if records_deleted == 0
      end
    end

    private

    def created_cut_off
      ApplicationSetting::USERS_UNCONFIRMED_SECONDARY_EMAILS_DELETE_AFTER_DAYS.days.ago
    end
  end
end
