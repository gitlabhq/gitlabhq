# frozen_string_literal: true

module EntityDateHelper
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TagHelper

  def interval_in_words(diff)
    return 'Not started' unless diff

    distance_of_time_in_words(Time.now, diff, scope: 'datetime.time_ago_in_words')
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
    mins %= 60
    days = (hours / 24).floor
    hours %= 24

    duration_hash = {}

    duration_hash[:days] = days if days > 0
    duration_hash[:hours] = hours if hours > 0
    duration_hash[:mins] = mins if mins > 0
    duration_hash[:seconds] = seconds if seconds > 0

    duration_hash
  end

  # Generates an HTML-formatted string for remaining dates based on start_date and due_date
  #
  # It returns "Past due" for expired entities
  # It returns "Upcoming" for upcoming entities
  # If due date is provided, it returns "# days|weeks|months remaining|ago"
  # If start date is provided and elapsed, with no due date, it returns "# days elapsed"
  def remaining_days_in_words(due_date, start_date = nil)
    if due_date&.past?
      content_tag(:strong, _('Past due'))
    elsif due_date&.today?
      content_tag(:strong, _('Today'))
    elsif start_date&.future?
      content_tag(:strong, _('Upcoming'))
    elsif due_date
      is_upcoming = (due_date - Date.today).to_i > 0
      time_ago = distance_of_time_in_words(due_date, Date.today)

      # https://gitlab.com/gitlab-org/gitlab-foss/issues/49440
      #
      # Need to improve the i18n here and do a full translation
      # of the string instead of piecewise translations.
      content = time_ago
        .gsub(/\d+/) { |match| "<strong>#{match}</strong>" }
        .remove('about ')
      remaining_or_ago = is_upcoming ? _('remaining') : _('ago')

      "#{content} #{remaining_or_ago}".html_safe
    elsif start_date&.past?
      days = (Date.today - start_date).to_i
      "#{content_tag(:strong, days)} #{'day'.pluralize(days)} elapsed".html_safe
    end
  end
end
