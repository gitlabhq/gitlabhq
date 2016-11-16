# == TimeTrackable concern
#
# Contains functionality related to objects that support time tracking.
#
# Used by Issue and MergeRequest.
#

module TimeTrackable
  extend ActiveSupport::Concern

  included do
    attr_reader :time_spent

    alias_method :time_spent?, :time_spent

    default_value_for :time_estimate, value: 0, allows_nil: false

    has_many :timelogs, as: :trackable, dependent: :destroy
  end

  def spend_time(seconds, user)
    return if seconds == 0

    @time_spent = seconds
    @time_spent_user = user

    if seconds == :reset
      reset_spent_time
    else
      add_or_susbtract_spent_time
    end
  end

  def spend_time!(seconds, user)
    spend_time(seconds, user)
    save!
  end

  def total_time_spent
    timelogs.sum(:time_spent)
  end

  def human_total_time_spent
    ChronicDuration.output(total_time_spent, format: :short)
  end

  def human_time_estimate
    ChronicDuration.output(time_estimate, format: :short)
  end

  private

  def reset_spent_time
    timelogs.new(time_spent: total_time_spent * -1, user: @time_spent_user)
  end

  def add_or_susbtract_spent_time
    # Exit if time to subtract exceeds the total time spent.
    return if time_spent < 0 && (time_spent.abs > total_time_spent)

    timelogs.new(time_spent: time_spent, user: @time_spent_user)
  end
end
