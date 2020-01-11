# frozen_string_literal: true

module Schedulable
  extend ActiveSupport::Concern

  included do
    scope :runnable_schedules, -> { active.where("next_run_at < ?", Time.zone.now) }

    before_save :set_next_run_at
  end

  def schedule_next_run!
    save! # with set_next_run_at
  rescue ActiveRecord::RecordInvalid
    update_column(:next_run_at, nil) # update without validation
  end

  def set_next_run_at
    raise NotImplementedError
  end
end
