module EntityDateHelper
  include ActionView::Helpers::DateHelper

  def interval_in_words(diff)
    return 'Not started' unless diff

    "#{distance_of_time_in_words(Time.now, diff)} ago"
  end

  # Converts seconds into a hash such as:
  # { days: 1, hours: 3, mins: 42, seconds: 40 }
  #
  # It returns 0 seconds for zero or negative numbers
  # It rounds to nearest time unit and does not return zero
  # i.e { min: 1 } instead of { mins: 1, seconds: 0 }
  def distance_of_time_as_hash(diff)
    diff = diff.abs.floor

    return { seconds: 0 } if diff == 0

    mins = (diff / 60).floor
    seconds = diff % 60
    hours = (mins / 60).floor
    mins = mins % 60
    days = (hours / 24).floor
    hours = hours % 24

    duration_hash = {}

    duration_hash[:days] = days if days > 0
    duration_hash[:hours] = hours if hours > 0
    duration_hash[:mins] = mins if mins > 0
    duration_hash[:seconds] = seconds if seconds > 0

    duration_hash
  end
end
