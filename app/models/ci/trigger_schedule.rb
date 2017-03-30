module Ci
  class TriggerSchedule < ActiveRecord::Base
    extend Ci::Model

    acts_as_paranoid

    belongs_to :project
    belongs_to :trigger

    delegate :ref, to: :trigger

    validates :trigger, presence: true
    validates :cron, presence: true
    validates :cron_time_zone, presence: true
    validate :check_cron
    validate :check_ref

    after_create :schedule_next_run!

    def schedule_next_run!
      puts "cron: #{cron.inspect} | cron_time_zone: #{cron_time_zone.inspect}"
      next_time = Ci::CronParser.new(cron, cron_time_zone).next_time_from_now
      if next_time.present?
        update!(next_run_at: next_time)
      end
    end

    def real_next_run(worker_cron: nil, worker_time_zone: nil)
      puts "worker_cron: #{worker_cron.inspect} | worker_time_zone: #{worker_time_zone.inspect}"
      worker_cron = Settings.cron_jobs['trigger_schedule_worker']['cron'] unless worker_cron.present?
      worker_time_zone = Time.zone.name unless worker_time_zone.present?
      worker_next_time = Ci::CronParser.new(worker_cron, worker_time_zone).next_time_from_now

      puts "next_run_at: #{next_run_at.inspect} | worker_next_time: #{worker_next_time.inspect}"
      if next_run_at > worker_next_time
        next_run_at
      else
        worker_next_time
      end
    end

    private

    def check_cron
      cron_parser = Ci::CronParser.new(cron, cron_time_zone)
      is_valid_cron, is_valid_cron_time_zone = cron_parser.validation

      if !is_valid_cron
        self.errors.add(:cron, " is invalid syntax")
      elsif !is_valid_cron_time_zone
        self.errors.add(:cron_time_zone, " is invalid timezone")
      elsif (cron_parser.next_time_from_now - Time.now).abs < 1.hour
        self.errors.add(:cron, " can not be less than 1 hour")
      end
    end

    def check_ref
      if !ref.present?
        self.errors.add(:ref, " is empty")
      elsif project.repository.ref_exists?(ref)
        self.errors.add(:ref, " does not exist")
      end
    end
  end
end
