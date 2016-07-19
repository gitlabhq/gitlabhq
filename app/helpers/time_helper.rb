module TimeHelper
  def time_interval_in_words(interval_in_seconds)
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

  def duration_in_numbers(finished_at, started_at)
    interval = interval_in_seconds(started_at, finished_at)
    time_format = interval < 1.hour ? "%M:%S" : "%H:%M:%S"

    Time.at(interval).utc.strftime(time_format)
  end

  private

  def interval_in_seconds(started_at, finished_at = nil)
    if started_at && finished_at
      finished_at.to_i - started_at.to_i
    elsif started_at
      Time.now.to_i - started_at.to_i
    end
  end
end
