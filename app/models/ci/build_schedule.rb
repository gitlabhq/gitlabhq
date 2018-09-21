# frozen_string_literal: true

module Ci
  class BuildSchedule < ActiveRecord::Base
    extend Gitlab::Ci::Model
    include Importable
    include AfterCommitQueue

    belongs_to :build

    validate :schedule_at_future

    after_create :schedule, unless: :importing?

    scope :stale, -> { where("execute_at < ?", Time.now) }

    def execute_in
      [0, self.execute_at - Time.now].max
    end

    private

    def schedule_at_future
      if self.execute_at < Time.now
        errors.add(:execute_at, "Excute point must be somewhere in the future")
      end
    end

    def schedule
      run_after_commit do
        Ci::BuildScheduleWorker.perform_at(self.execute_at, self.build_id)
      end
    end
  end
end
