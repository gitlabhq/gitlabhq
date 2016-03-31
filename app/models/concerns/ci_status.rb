module CiStatus
  extend ActiveSupport::Concern

  module ClassMethods
    def status
      if all.none?
         nil
      elsif all.all? { |status| status.success? || status.ignored? }
        'success'
      elsif all.all?(&:pending?)
        'pending'
      elsif all.any?(&:running?) || all.any?(&:pending?)
        'running'
      elsif all.all?(&:canceled?)
        'canceled'
      else
        'failed'
      end
    end

    def duration
      duration_array = all.map(&:duration).compact
      duration_array.reduce(:+).to_i
    end
  end

  included do
    validates :status, inclusion: { in: %w(pending running failed success canceled) }

    state_machine :status, initial: :pending do
      state :pending, value: 'pending'
      state :running, value: 'running'
      state :failed, value: 'failed'
      state :success, value: 'success'
      state :canceled, value: 'canceled'
    end
  end

  def started?
    !pending? && !canceled? && started_at
  end

  def active?
    running? || pending?
  end

  def complete?
    canceled? || success? || failed?
  end
end