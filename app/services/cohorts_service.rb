# frozen_string_literal: true

class CohortsService
  MONTHS_INCLUDED = 12

  def execute
    {
      months_included: MONTHS_INCLUDED,
      cohorts: cohorts
    }
  end

  # Get an array of hashes that looks like:
  #
  #     [
  #       {
  #         registration_month: Date.new(2017, 3),
  #         activity_months: [3, 2, 1],
  #         total: 3
  #         inactive: 0
  #      },
  #      etc.
  #
  # The `months` array is always from oldest to newest, so it's always
  # non-strictly decreasing from left to right.
  def cohorts
    months = Array.new(MONTHS_INCLUDED) { |i| i.months.ago.beginning_of_month.to_date }

    Array.new(MONTHS_INCLUDED) do
      registration_month = months.last
      activity_months = running_totals(months, registration_month)

      # Even if no users registered in this month, we always want to have a
      # value to fill in the table.
      inactive = counts_by_month[[registration_month, nil]].to_i

      months.pop

      {
        registration_month: registration_month,
        activity_months: activity_months[1..-1],
        total: activity_months.first[:total],
        inactive: inactive
      }
    end
  end

  private

  # Calculate a running sum of active users, so users active in later months
  # count as active in this month, too. Start with the most recent month first,
  # for calculating the running totals, and then reverse for displaying in the
  # table.
  #
  # Each month has a total, and a percentage of the overall total, as keys.
  def running_totals(all_months, registration_month)
    month_totals =
      all_months
        .map { |activity_month| counts_by_month[[registration_month, activity_month]] }
        .reduce([]) { |result, total| result << result.last.to_i + total.to_i }
        .reverse

    overall_total = month_totals.first

    month_totals.map do |total|
      { total: total, percentage: total.zero? ? 0 : 100 * total / overall_total }
    end
  end

  # Get a hash that looks like:
  #
  #     {
  #       [created_at_month, last_activity_on_month] => count,
  #       [created_at_month, last_activity_on_month_2] => count_2,
  #       # etc.
  #     }
  #
  # created_at_month can never be nil, but last_activity_on_month can (when a
  # user has never logged in, just been created). This covers the last
  # MONTHS_INCLUDED months.
  # rubocop: disable CodeReuse/ActiveRecord
  def counts_by_month
    @counts_by_month ||=
      begin
        created_at_month = column_to_date('created_at')
        last_activity_on_month = column_to_date('last_activity_on')

        User
          .where('created_at > ?', MONTHS_INCLUDED.months.ago.end_of_month)
          .group(created_at_month, last_activity_on_month)
          .reorder(Arel.sql("#{created_at_month} ASC, #{last_activity_on_month} ASC"))
          .count
      end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def column_to_date(column)
    "CAST(DATE_TRUNC('month', #{column}) AS date)"
  end
end
