# frozen_string_literal: true

module TimeHelper
  TIME_UNIT_TRANSLATION = {
    seconds: ->(seconds) { n_('%d second', '%d seconds', seconds) % seconds },
    minutes: ->(minutes) { n_('%d minute', '%d minutes', minutes) % minutes },
    hours: ->(hours) { n_('%d hour', '%d hours', hours) % hours },
    days: ->(days) { n_('%d day', '%d days', days) % days },
    weeks: ->(weeks) { n_('%d week', '%d weeks', weeks) % weeks },
    months: ->(months) { n_('%d month', '%d months', months) % months },
    years: ->(years) { n_('%d year', '%d years', years) % years }
  }.freeze

  def time_interval_in_words(interval_in_seconds)
    time_parts = ActiveSupport::Duration.build(interval_in_seconds.to_i).parts

    time_parts.map { |unit, value| TIME_UNIT_TRANSLATION[unit].call(value) }.to_sentence
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
