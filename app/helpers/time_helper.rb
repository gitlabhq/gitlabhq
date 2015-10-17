module TimeHelper
  def duration_in_words(finished_at, started_at)
    if finished_at && started_at
      interval_in_seconds = finished_at.to_i - started_at.to_i
    elsif started_at
      interval_in_seconds = Time.now.to_i - started_at.to_i
    end

    time_interval_in_words(interval_in_seconds)
  end

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
end
