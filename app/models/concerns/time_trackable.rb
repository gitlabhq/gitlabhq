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

  def spend_time=(args)
    return unless valid_spend_time_args?(args)

    seconds = args[:seconds]
    new_time_spent = seconds.zero? ? -(total_time_spent) : seconds

    timelogs.new(user: args[:user], time_spent: new_time_spent)

    @time_spent = seconds
  end

  def total_time_spent
    timelogs.sum(:time_spent)
  end

  private

  def valid_spend_time_args?(args)
    return false unless [:seconds, :user].all? { |k| args.key?(k) }

    # time to subtract exceeds the total time spent
    seconds = args[:seconds]
    return false if seconds < 0 && (seconds.abs > total_time_spent)

    true
  end
end
