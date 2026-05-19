# frozen_string_literal: true

module Gitlab
  module BackgroundOperation
    class UsersDeleteUnconfirmedSecondaryEmails < BaseOperationWorker
      operation_name :delete_all
      feature_category :user_management
      cursor :id

      scope_to ->(relation) { relation.where('created_at < ? AND confirmed_at IS NULL', created_cut_off) } # rubocop:disable CodeReuse/ActiveRecord -- Specific use-case
      reset_cursor!

      def perform
        each_sub_batch do |sub_batch|
          ids = sub_batch.pluck(:id) # rubocop:disable CodeReuse/ActiveRecord -- need to get IDs for deletion
          next if ids.empty?

          emails = ::Email.where(id: ids).to_a if cells_claims_enabled? # rubocop:disable CodeReuse/ActiveRecord -- need Email records for claims metadata
          deleted = sub_batch.delete_all
          schedule_bulk_claims_destroy(emails) if cells_claims_enabled?
          deleted
        end
      end

      private

      def cells_claims_enabled?
        ::Email.cells_claims_enabled_for_attribute?(:email)
      end

      def schedule_bulk_claims_destroy(records)
        return if records.blank?

        destroy_metadata = records.filter_map { |record| record.build_destroy_metadata_for_worker(:email) }
        return if destroy_metadata.empty?

        destroy_metadata.each_slice(::Cells::Claimable::BULK_CLAIMS_BATCH_SIZE) do |batch|
          ::Cells::BulkClaimsWorker.perform_async(::Email.name, 'email', { 'destroy_metadata' => batch })
        end
      end

      def created_cut_off
        ApplicationSetting::USERS_UNCONFIRMED_SECONDARY_EMAILS_DELETE_AFTER_DAYS.days.ago
      end
    end
  end
end
