# frozen_string_literal: true

module Ci
  class RunnerMachine < Ci::ApplicationRecord
    include FromUnion
    include Ci::HasRunnerExecutor

    belongs_to :runner

    validates :runner, presence: true
    validates :machine_xid, presence: true, length: { maximum: 64 }
    validates :version, length: { maximum: 2048 }
    validates :revision, length: { maximum: 255 }
    validates :platform, length: { maximum: 255 }
    validates :architecture, length: { maximum: 255 }
    validates :ip_address, length: { maximum: 1024 }
    validates :config, json_schema: { filename: 'ci_runner_config' }

    # The `STALE_TIMEOUT` constant defines the how far past the last contact or creation date a runner machine
    # will be considered stale
    STALE_TIMEOUT = 7.days

    scope :stale, -> do
      created_some_time_ago = arel_table[:created_at].lteq(STALE_TIMEOUT.ago)
      contacted_some_time_ago = arel_table[:contacted_at].lteq(STALE_TIMEOUT.ago)

      from_union(
        where(contacted_at: nil),
        where(contacted_some_time_ago),
        remove_duplicates: false).where(created_some_time_ago)
    end
  end
end
