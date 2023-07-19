# frozen_string_literal: true

module CalendarHelper
  def calendar_url_options
    { format: :ics,
      feed_token: generate_feed_token(:ics),
      due_date: Issue::DueNextMonthAndPreviousTwoWeeks.name,
      sort: 'closest_future_date' }
  end
end
