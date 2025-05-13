# frozen_string_literal: true

module Import
  class PlaceholderUserDetail < ApplicationRecord
    self.table_name = 'import_placeholder_user_details'

    DELETION_RETRY_PERIOD = 2.days

    belongs_to :placeholder_user, class_name: 'User', inverse_of: :placeholder_user_detail
    belongs_to :namespace
    belongs_to :organization, class_name: 'Organizations::Organization'

    validates :deletion_attempts, numericality: { greater_than_or_equal_to: 0 }
    validates :placeholder_user, presence: true

    def self.eligible_for_deletion(max_attempts = PlaceholderUserCleanupWorker::MAX_ATTEMPTS)
      base_query = where(deletion_attempts: ...max_attempts, namespace_id: nil)

      never_attempted_records = base_query.where(last_deletion_attempt_at: nil)
      retry_eligible_records = base_query.where(last_deletion_attempt_at: ...DELETION_RETRY_PERIOD.ago)

      from(
        "(#{never_attempted_records.to_sql} UNION " \
          "#{retry_eligible_records.to_sql}) AS import_placeholder_user_details"
      ).select('import_placeholder_user_details.*')
    end

    def increment_deletion_attempt
      ::Import::PlaceholderUserDetail.increment_counter(:deletion_attempts, id, touch: :last_deletion_attempt_at)
    end
  end
end
