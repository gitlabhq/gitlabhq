class UserCohortsService
  MONTHS_INCLUDED = 12

  # Get a hash that looks like:
  #
  #     {
  #       month => {
  #         months: [3, 2, 1],
  #         total: 3
  #         inactive: 0
  #      },
  #      etc.
  #
  # The `months` array is always from oldest to newest, so it's always
  # non-strictly decreasing from left to right.
  #
  def execute
    cohorts = {}
    months = Array.new(MONTHS_INCLUDED) { |i| i.months.ago.beginning_of_month.to_date }

    MONTHS_INCLUDED.times do
      created_at_month = months.last
      activity_months = running_totals(months, created_at_month)

      # Even if no users registered in this month, we always want to have a
      # value to fill in the table.
      inactive = counts_by_month[[created_at_month, nil]].to_i

      cohorts[created_at_month] = {
        months: activity_months,
        total: activity_months.first,
        inactive: inactive
      }

      months.pop
    end

    cohorts
  end

  private

  # Calculate a running sum of active users, so users active in later months
  # count as active in this month, too. Start with the most recent month first,
  # for calculating the running totals, and then reverse for displaying in the
  # table.
  def running_totals(all_months, created_at_month)
    all_months
      .map { |activity_month| counts_by_month[[created_at_month, activity_month]] }
      .reduce([]) { |result, total| result << result.last.to_i + total.to_i }
      .reverse
  end

  # Get a hash that looks like:
  #
  #     {
  #       [created_at_month, current_sign_in_at_month] => count,
  #       [created_at_month, current_sign_in_at_month_2] => count_2,
  #       # etc.
  #     }
  #
  # created_at_month can never be nil, but current_sign_in_at_month can (when a
  # user has never logged in, just been created). This covers the last twelve
  # months.
  #
  def counts_by_month
    @counts_by_month ||=
      begin
        created_at_month = column_to_date('created_at')
        current_sign_in_at_month = column_to_date('current_sign_in_at')

        User
          .where('created_at > ?', MONTHS_INCLUDED.months.ago.end_of_month)
          .group(created_at_month, current_sign_in_at_month)
          .reorder("#{created_at_month} ASC", "#{current_sign_in_at_month} ASC")
          .count
      end
  end

  def column_to_date(column)
    if Gitlab::Database.postgresql?
      "CAST(DATE_TRUNC('month', #{column}) AS date)"
    elsif Gitlab::Database.mysql?
      "STR_TO_DATE(DATE_FORMAT(#{column}, '%Y-%m-01'), '%Y-%m-%d')"
    end
  end
end
