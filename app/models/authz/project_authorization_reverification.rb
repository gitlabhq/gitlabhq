# frozen_string_literal: true

module Authz
  class ProjectAuthorizationReverification < ApplicationRecord
    ENQUEUE_BATCH_SIZE = 1_000
    CLAIM_BATCH_SIZE = 50

    PROCESSING_TIMEOUT = 1.hour
    MIN_AGE = 1.hour

    belongs_to :user, optional: false

    enum :status, { pending: 0, processing: 1, requeued: 2 }

    scope :abandoned, -> { processing.where(refresh_started_at: ...PROCESSING_TIMEOUT.ago) }

    scope :to_be_processed, -> {
      where(status: [:pending, :requeued])
      .where(enqueued_at: ...MIN_AGE.ago)
      .order(:enqueued_at)
    }

    def self.queue_users(user_ids)
      user_ids.uniq.each_slice(ENQUEUE_BATCH_SIZE) do |ids|
        existing_ids = User.id_in(ids).limit(ENQUEUE_BATCH_SIZE).pluck(:id)
        next if existing_ids.empty?

        now = Time.current
        rows = existing_ids.map { |user_id| { user_id: user_id, status: :pending, enqueued_at: now } }

        upsert_all(
          rows,
          unique_by: :user_id,
          on_duplicate: Arel.sql(<<~SQL.squish)
            status = #{statuses[:requeued]},
            enqueued_at = excluded.enqueued_at
            WHERE #{table_name}.status = #{statuses[:processing]}
          SQL
        )
      rescue ActiveRecord::InvalidForeignKey => e
        Gitlab::ErrorTracking.track_exception(e, user_ids: ids)
      end
    end

    def self.claim_batch
      transaction do
        ids = to_be_processed.lock('FOR UPDATE SKIP LOCKED').limit(CLAIM_BATCH_SIZE).pluck(:id)
        next [] if ids.empty?

        scope = where(id: ids)
        scope.update_all(status: :processing, refresh_started_at: Time.current)
        scope.preload(:user)
      end
    end

    def processed
      self.class.processing.id_in(id).delete_all
    end
  end
end
