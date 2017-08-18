# == TimeTrackable concern
#
# Contains functionality related to objects that support time tracking.
#
# Used by Issue and MergeRequest.
#

module TimeTrackable
  extend ActiveSupport::Concern

  included do
    attr_reader :time_spent, :time_spent_user

    alias_method :time_spent?, :time_spent

    default_value_for :time_estimate, value: 0, allows_nil: false

    validates :time_estimate, numericality: { message: 'has an invalid format' }, allow_nil: false
    validate  :check_negative_time_spent

    has_many :timelogs, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  end

  def spend_time(options)
    @time_spent = options[:duration]
    @time_spent_user = options[:user]
    @original_total_time_spent = nil

    return if @time_spent == 0

    if @time_spent == :reset
      reset_spent_time
    else
      add_or_subtract_spent_time
    end
  end
  alias_method :spend_time=, :spend_time

  def total_time_spent
    timelogs.sum(:time_spent)
  end

  def human_total_time_spent
    Gitlab::TimeTrackingFormatter.output(total_time_spent)
  end

  def human_time_estimate
    Gitlab::TimeTrackingFormatter.output(time_estimate)
  end

  private

  def reset_spent_time
    timelogs.new(time_spent: total_time_spent * -1, user: @time_spent_user)
  end

  def add_or_subtract_spent_time
    timelogs.new(time_spent: time_spent, user: @time_spent_user)
  end

  def check_negative_time_spent
    return if time_spent.nil? || time_spent == :reset

    # we need to cache the total time spent so multiple calls to #valid?
    # doesn't give a false error
    @original_total_time_spent ||= total_time_spent

    if time_spent < 0 && (time_spent.abs > @original_total_time_spent)
      errors.add(:time_spent, 'Time to subtract exceeds the total time spent')
    end
  end
end
