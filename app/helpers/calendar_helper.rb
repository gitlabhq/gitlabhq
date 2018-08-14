module CalendarHelper
  def calendar_url_options
    { format: :ics,
      feed_token: current_user.try(:feed_token),
      due_date: Issue::DueNextMonthAndPreviousTwoWeeks.name,
      sort: 'closest_future_date' }
  end
end
