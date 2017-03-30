class UserCohortsService
  def initialize
  end

  def execute(months_included)
    if Gitlab::Database.postgresql?
      created_at_month = "CAST(DATE_TRUNC('month', created_at) AS date)"
      current_sign_in_at_month = "CAST(DATE_TRUNC('month', current_sign_in_at) AS date)"
    elsif Gitlab::Database.mysql?
      created_at_month = "STR_TO_DATE(DATE_FORMAT(created_at, '%Y-%m-01'), '%Y-%m-%d')"
      current_sign_in_at_month = "STR_TO_DATE(DATE_FORMAT(current_sign_in_at, '%Y-%m-01'), '%Y-%m-%d')"
    end

    counts_by_month =
      User
        .where('created_at > ?', months_included.months.ago.end_of_month)
        .group(created_at_month, current_sign_in_at_month)
        .reorder("#{created_at_month} ASC", "#{current_sign_in_at_month} DESC")
        .count

    cohorts = {}
    months = Array.new(months_included) { |i| i.months.ago.beginning_of_month.to_date }

    months_included.times do
      month = months.last
      inactive = counts_by_month[[month, nil]] || 0

      # Calculate a running sum of active users, so users active in later months
      # count as active in this month, too. Start with the most recent month
      # first, for calculating the running totals, and then reverse for
      # displaying in the table.
      activity_months =
        months
          .map { |activity_month| counts_by_month[[month, activity_month]] }
          .reduce([]) { |result, total| result << result.last.to_i + total.to_i }
          .reverse

      cohorts[month] = {
        months: activity_months,
        total: activity_months.first,
        inactive: inactive
      }

      months.pop
    end

    cohorts
  end
end
