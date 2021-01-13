# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfill expire_at for a range of Ci::JobArtifact
    class BackfillArtifactExpiryDate
      include Gitlab::Utils::StrongMemoize

      BATCH_SIZE = 1_000
      DEFAULT_EXPIRATION_SWITCH_DATE = Date.new(2020, 6, 22).freeze
      OLD_ARTIFACT_AGE = 15.months
      OLD_ARTIFACT_EXPIRY_OFFSET = 3.months
      RECENT_ARTIFACT_EXPIRY_OFFSET = 1.year

      # Ci::JobArtifact model
      class Ci::JobArtifact < ActiveRecord::Base
        include ::EachBatch

        self.table_name = 'ci_job_artifacts'

        scope :between, -> (start_id, end_id) { where(id: start_id..end_id) }
        scope :before_default_expiration_switch, -> { where('created_at < ?', DEFAULT_EXPIRATION_SWITCH_DATE) }
        scope :without_expiry_date, -> { where(expire_at: nil) }
        scope :old, -> { where(self.arel_table[:created_at].lt(OLD_ARTIFACT_AGE.ago)) }
        scope :recent, -> { where(self.arel_table[:created_at].gt(OLD_ARTIFACT_AGE.ago)) }
      end

      def perform(start_id, end_id)
        Ci::JobArtifact.between(start_id, end_id)
          .without_expiry_date.before_default_expiration_switch
          .each_batch(of: BATCH_SIZE) do |batch|
          batch.old.update_all(expire_at: old_artifact_expiry_date)
          batch.recent.update_all(expire_at: recent_artifact_expiry_date)
        end
      end

      private

      def offset_date
        strong_memoize(:offset_date) do
          current_date = Time.current
          target_date = Time.zone.local(current_date.year, current_date.month, 22, 0, 0, 0)

          current_date.day < 22 ? target_date : target_date.next_month
        end
      end

      def old_artifact_expiry_date
        offset_date + OLD_ARTIFACT_EXPIRY_OFFSET
      end

      def recent_artifact_expiry_date
        offset_date + RECENT_ARTIFACT_EXPIRY_OFFSET
      end
    end
  end
end
