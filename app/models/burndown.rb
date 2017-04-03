class Burndown
  attr_accessor :start_date, :end_date, :issues_count, :issues_weight

  def initialize(milestone)
    @milestone = milestone
    @start_date = @milestone.start_date
    @end_date = @milestone.due_date
    @end_date = Date.today if @end_date.present? && @end_date > Date.today

    milestone_issues = @milestone.issues

    @issues_count  = milestone_issues.count
    @issues_weight = milestone_issues.sum(:weight)
  end

  # Returns the chart data in the following format:
  # [date, issue count, issue weight] eg: [["2017-03-01", 33, 127], ["2017-03-02", 35, 73], ["2017-03-03", 28, 50]...]
  def chart_data
    return [] unless valid?

    open_issues_count  = issues_count
    open_issues_weight = issues_weight

    start_date.upto(end_date).each_with_object([]) do |date, chart_data|
      closed, reopened = closed_and_reopened_issues_by(date)

      closed_issues_count = closed.count
      closed_issues_weight = sum_issues_weight(closed)

      chart_data << [date.strftime("%Y-%m-%d"), open_issues_count -= closed_issues_count, open_issues_weight -= closed_issues_weight]

      reopened_count = reopened.count
      reopened_weight = sum_issues_weight(reopened)

      open_issues_count += reopened_count
      open_issues_weight += reopened_weight
    end
  end

  def valid?
    start_date && end_date
  end

  private

  def sum_issues_weight(issues)
    issues.map(&:weight).compact.reduce(:+) || 0
  end

  def closed_and_reopened_issues_by(date)
    current_date = date.beginning_of_day

    closed   = issues_with_closed_at.select { |issue| issue.closed_at.beginning_of_day.to_i == current_date.to_i }
    reopened = closed.select { |issue| issue.state == 'reopened' }

    return closed, reopened
  end

  def issues_with_closed_at
    @issues ||=
      @milestone.issues.select('closed_at, weight, state').
      where('closed_at IS NOT NULL').
      order('closed_at ASC')
  end
end
