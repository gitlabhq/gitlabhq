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

  def time_in_milliseconds
    (Time.now.to_f * 1000).to_i
  end
end
