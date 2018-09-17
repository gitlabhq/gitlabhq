# frozen_string_literal: true

module Ci
  class BuildSchedule < ActiveRecord::Base
    extend Gitlab::Ci::Model
    include Importable
    include AfterCommitQueue

    belongs_to :build

    after_create :schedule, unless: :importing?

    def execute_in
      self.execute_at - Time.now
    end

    private

    def schedule
      run_after_commit do
        Ci::BuildScheduleWorker.perform_at(self.execute_at, self.build_id)
      end
    end
  end
end
