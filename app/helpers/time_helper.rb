module TimeHelper
  def time_interval_in_words(interval_in_seconds)
    interval_in_seconds = interval_in_seconds.to_i
    minutes = interval_in_seconds / 60
    seconds = interval_in_seconds - minutes * 60

    if minutes >= 1
      "#{pluralize(minutes, "minute")} #{pluralize(seconds, "second")}"
    else
      "#{pluralize(seconds, "second")}"
    end
  end

  def date_from_to(from, to)
    "#{from.to_s(:short)} - #{to.to_s(:short)}"
  end

  def duration_in_numbers(duration)
    time_format = duration < 1.hour ? "%M:%S" : "%H:%M:%S"

    Time.at(duration).utc.strftime(time_format)
  end
end
