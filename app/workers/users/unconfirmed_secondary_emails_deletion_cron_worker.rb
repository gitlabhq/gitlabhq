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
    BULK_CLAIMS_BATCH_SIZE = Cells::Claimable::BULK_CLAIMS_BATCH_SIZE

    def perform
      loop do
        records = Email.unconfirmed_and_created_before(created_cut_off).limit(BATCH_SIZE).to_a
        break if records.empty?

        deleted_count = Email.delete(records.map(&:id))

        if Email.cells_claims_enabled_for_attribute?(:email)
          destroy_metadata = records.filter_map { |record| record.build_destroy_metadata_for_worker(:email) }
          schedule_bulk_claims_destroy(destroy_metadata)
        end

        break if deleted_count < BATCH_SIZE
      end
    end

    private

    def schedule_bulk_claims_destroy(destroy_metadata)
      return if destroy_metadata.empty?

      destroy_metadata.each_slice(BULK_CLAIMS_BATCH_SIZE) do |batch|
        Cells::BulkClaimsWorker.perform_async(Email.name, 'email', { 'destroy_metadata' => batch })
      end
    end

    def created_cut_off
      ApplicationSetting::USERS_UNCONFIRMED_SECONDARY_EMAILS_DELETE_AFTER_DAYS.days.ago
    end
  end
end
