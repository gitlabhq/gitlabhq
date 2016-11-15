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

    has_many :timelogs, as: :trackable, dependent: :destroy
  end

  def spend_time=(seconds:, user:)
    # Exit if time to subtract exceeds the total time spent.
    return if seconds < 0 && (seconds.abs > total_time_spent)

    # When seconds = 0 we reset the total time spent by creating a new Timelog
    # record with a negative value that is equal to the current total time spent.
    new_time_spent = seconds.zero? ? (total_time_spent * -1) : seconds

    timelogs.new(user: user, time_spent: new_time_spent)

    @time_spent = seconds
  end

  def total_time_spent
    timelogs.sum(:time_spent)
  end
end
