# frozen_string_literal: true

module TimeHelper
  def time_interval_in_words(interval_in_seconds)
    interval_in_seconds = interval_in_seconds.to_i
    minutes = interval_in_seconds / 60
    seconds = interval_in_seconds - minutes * 60

    if minutes >= 1
      if seconds % 60 == 0
        pluralize(minutes, "minute")
      else
        [pluralize(minutes, "minute"), pluralize(seconds, "second")].to_sentence
      end
    else
      pluralize(seconds, "second")
    end
  end

  def date_from_to(from, to)
    "#{from.to_s(:short)} - #{to.to_s(:short)}"
  end

  def duration_in_numbers(duration_in_seconds)
    seconds = duration_in_seconds % 1.minute
    minutes = (duration_in_seconds / 1.minute) % (1.hour / 1.minute)
    hours = duration_in_seconds / 1.hour

    if hours == 0
      "%02d:%02d" % [minutes, seconds]
    else
      "%02d:%02d:%02d" % [hours, minutes, seconds]
    end
  end

  def time_in_milliseconds
    (Time.now.to_f * 1000).to_i
  end
end
