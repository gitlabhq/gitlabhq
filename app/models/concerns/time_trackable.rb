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
  end

  def spend_time=(seconds)
    return if invalid_time_spent?(seconds)

    new_time_spent = seconds.zero? ? -(total_time_spent) : seconds
    timelogs.new(time_spent: new_time_spent)

    @time_spent = seconds
  end

  def total_time_spent
    timelogs.sum(:time_spent)
  end

  private

  def invalid_time_spent?(seconds)
    return true unless seconds
    # time to subtract exceeds the total time spent
    return true if seconds < 0 && (seconds.abs > total_time_spent)

    false
  end
end
