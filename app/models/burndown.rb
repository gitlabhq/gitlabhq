class Burndown
  attr_accessor :start_date, :end_date, :issues_count, :issues_weight

  def initialize(milestone)
    @milestone = milestone
    @start_date = @milestone.start_date
    @end_date = @milestone.due_date
    @end_date = Date.today if @end_date.present? && @end_date > Date.today

    issues = @milestone.issues

    @issues_count  = issues.count
    @issues_weight = issues.sum(:weight)
  end

  # Returns the chart data in the following format:
  # [date, issue count, issue weight] eg: [["2017-03-01", 33, 127], ["2017-03-02", 35, 73], ["2017-03-03", 28, 50]...]
  def chart_data
    return [] unless @start_date && @end_date

    open_count = @issues_count
    open_weight = @issues_weight

    @start_date.upto(@end_date).each_with_object([]) do |date, chart_data|
      closed, reopened = opened_and_closed_issues_by(date)

      closed_count, closed_weight = count_and_weight_of(closed)
      chart_data << [date.strftime("%Y-%m-%d"), open_count -= closed_count, open_weight -= closed_weight]

      reopened_count, reopened_weight = count_and_weight_of(reopened)
      open_count += reopened_count
      open_weight += reopened_weight
    end
  end

  private

  def count_and_weight_of(issues)
    weight = issues.map{ |i| i.weight }.compact.reduce(:+)

    return issues.count, weight || 0
  end

  def opened_and_closed_issues_by(date)
    current_date = date.beginning_of_day

    closed   = issues.select { |issue| issue.closed_at.beginning_of_day.to_i == current_date.to_i }
    reopened = closed.select { |issue| issue.state == 'reopened' }

    return closed, reopened
  end

  def issues
    @issues ||=
      @milestone.issues.select('closed_at, weight, state').
      where('closed_at IS NOT NULL').
      order('closed_at ASC')
  end
end
