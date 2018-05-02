class Burndown
  class Issue
    attr_reader :closed_at, :weight, :state

    def initialize(closed_at, weight, state)
      @closed_at = closed_at
      @weight = weight
      @state = state
    end

    def reopened?
      @state == 'opened' && @closed_at.present?
    end
  end

  attr_reader :start_date, :due_date, :end_date, :issues_count, :issues_weight, :accurate, :legacy_data
  alias_method :accurate?, :accurate
  alias_method :empty?, :legacy_data

  def initialize(milestone)
    @milestone = milestone
    @start_date = @milestone.start_date
    @due_date = @milestone.due_date
    @end_date = @milestone.due_date
    @end_date = Date.today if @end_date.present? && @end_date > Date.today

    @accurate = milestone_issues.all?(&:closed_at)
    @legacy_data = milestone_issues.any? && milestone_issues.none?(&:closed_at)

    @issues_count, @issues_weight = milestone.issues.reorder(nil).pluck('COUNT(*), COALESCE(SUM(weight), 0)').first
  end

  # Returns the chart data in the following format:
  # [date, issue count, issue weight] eg: [["2017-03-01", 33, 127], ["2017-03-02", 35, 73], ["2017-03-03", 28, 50]...]
  def as_json(opts = nil)
    return [] unless valid?

    open_issues_count  = issues_count
    open_issues_weight = issues_weight

    start_date.upto(end_date).each_with_object([]) do |date, chart_data|
      closed, reopened = closed_and_reopened_issues_by(date)

      closed_issues_count = closed.count
      closed_issues_weight = sum_issues_weight(closed)

      open_issues_count -= closed_issues_count
      open_issues_weight -= closed_issues_weight

      chart_data << [date.strftime("%Y-%m-%d"), open_issues_count, open_issues_weight]

      reopened_count = reopened.count
      reopened_weight = sum_issues_weight(reopened)

      open_issues_count += reopened_count
      open_issues_weight += reopened_weight
    end
  end

  def valid?
    start_date && due_date
  end

  private

  def sum_issues_weight(issues)
    issues.map(&:weight).compact.sum
  end

  def closed_and_reopened_issues_by(date)
    current_date = date.to_date

    closed =
      milestone_issues.select do |issue|
        (issue.closed_at&.to_date || start_date) == current_date
      end

    reopened = closed.select(&:reopened?)

    [closed, reopened]
  end

  def milestone_issues
    @milestone_issues ||=
      begin
        # We make use of `events` table to get the closed_at timestamp.
        # `issues.closed_at` can't be used once it's nullified if the issue is
        # reopened.
        internal_clause =
          ::Issue
            .joins("LEFT OUTER JOIN events e ON issues.id = e.target_id AND e.target_type = 'Issue' AND e.action = #{Event::CLOSED}") # rubocop:disable GitlabSecurity/SqlInjection
            .where(milestone: @milestone)
            .where("state = 'closed' OR (state = 'opened' AND e.action = #{Event::CLOSED})") # rubocop:disable GitlabSecurity/SqlInjection

        rel =
          if Gitlab::Database.postgresql?
            ::Issue
              .select("*")
              .from(internal_clause.select('DISTINCT ON (issues.id) issues.id, issues.state, issues.weight, e.created_at AS closed_at'))
          else
            ::Issue
              .select("*")
              .from(internal_clause.select('issues.id, issues.state, issues.weight, e.created_at AS closed_at'))
              .group('id')
              .having('closed_at = MIN(closed_at) OR closed_at IS NULL')
          end

        rel
          .order('closed_at ASC')
          .pluck('closed_at, weight, state')
          .map { |attrs| Issue.new(*attrs) }
      end
  end
end
