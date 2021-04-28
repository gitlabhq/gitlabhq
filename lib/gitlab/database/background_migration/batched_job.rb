# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundMigration
      class BatchedJob < ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord
        self.table_name = :batched_background_migration_jobs

        belongs_to :batched_migration, foreign_key: :batched_background_migration_id

        enum status: {
          pending: 0,
          running: 1,
          failed: 2,
          succeeded: 3
        }

        scope :successful_in_execution_order, -> { where.not(finished_at: nil).succeeded.order(:finished_at) }

        delegate :aborted?, :job_class, :table_name, :column_name, :job_arguments,
          to: :batched_migration, prefix: :migration

        attribute :pause_ms, :integer, default: 100

        def time_efficiency
          return unless succeeded?
          return unless finished_at && started_at

          duration = finished_at - started_at

          # TODO: Switch to individual job interval (prereq: https://gitlab.com/gitlab-org/gitlab/-/issues/328801)
          duration.to_f / batched_migration.interval
        end
      end
    end
  end
end
