# frozen_string_literal: true

module TimeFrameFilter
  def by_timeframe(items)
    return items unless params[:start_date] && params[:end_date]

    start_date = params[:start_date].to_date
    end_date = params[:end_date].to_date

    items.within_timeframe(start_date, end_date)
  rescue ArgumentError
    items
  end

  def containing_date(items)
    return items unless params[:containing_date]

    date = params[:containing_date].to_date
    items.within_timeframe(date, date)
  end
end
