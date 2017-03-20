class Burndown
  attr_accessor :start_date, :end_date, :open_issues_count, :open_issues_weight

  def initialize(milestone)
    @milestone          = milestone
    @start_date         = @milestone.start_date
    @end_date           = @milestone.due_date

    open_issues         = @milestone.issues.opened

    @open_issues_count  = open_issues.count
    @open_issues_weight = open_issues.sum(:weight)
  end

  def closed_issues
    return {} unless @start_date && @end_date

    Hash[
      get_count.map do |row|
        [row.date.strftime('%d %b'), [row.count, row.weight]]
      end
    ]
  end

  private

  def get_count
    start_date = @start_date.to_time.beginning_of_day
    end_date = @end_date.to_time.end_of_day

    @milestone.issues.
      select("DATE_TRUNC('day', closed_at) AS date, COUNT(*) AS count, SUM(weight) as weight").
      where('closed_at BETWEEN (?) AND (?) AND state = ?', start_date, end_date, 'closed').
      group(1).reorder(1)
  end
end
