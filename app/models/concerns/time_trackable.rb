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
    return unless seconds

    new_time_spent = seconds.zero? ? -(total_time_spent) : seconds
    timelogs.new(time_spent: new_time_spent)

    @time_spent = seconds
  end

  def total_time_spent
    timelogs.sum(:time_spent)
  end
end
