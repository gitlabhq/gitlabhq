class Burndown
  include Gitlab::Utils::StrongMemoize

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

  attr_reader :start_date, :due_date, :end_date, :accurate, :legacy_data, :milestone
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
  end

  # Returns the chart data in the following format:
  # [date, issue count, issue weight] eg: [["2017-03-01", 33, 127], ["2017-03-02", 35, 73], ["2017-03-03", 28, 50]...]
  def as_json(opts = nil)
    return [] unless valid?

    open_issues_count = 0
    open_issues_weight = 0

    start_date.upto(end_date).each_with_object([]) do |date, chart_data|
      closed, reopened = closed_and_reopened_issues_by(date)

      closed_issues_count = closed.count
      closed_issues_weight = sum_issues_weight(closed)

      issues_created = opened_issues_on(date)
      open_issues_count += issues_created.count
      open_issues_weight += sum_issues_weight(issues_created)

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

  def opened_issues_on(date)
    return {} if opened_issues_grouped_by_date.empty?

    date = date.to_date

    # If issues.created_at < milestone.start_date
    # we consider all of them created at milestone.start_date
    if date == start_date
      first_issue_created_at = opened_issues_grouped_by_date.keys.first
      days_before_start_date = start_date.downto(first_issue_created_at).to_a
      opened_issues_grouped_by_date.values_at(*days_before_start_date).flatten.compact
    else
      opened_issues_grouped_by_date[date] || []
    end
  end

  def opened_issues_grouped_by_date
    strong_memoize(:opened_issues_grouped_by_date) do
      issues =
        @milestone
          .issues
          .where('created_at <= ?', end_date)
          .reorder(nil)
          .order(:created_at).to_a

      issues.group_by do |issue|
        issue.created_at.to_date
      end
    end
  end

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
            .joins("LEFT OUTER JOIN events e ON issues.id = e.target_id AND e.target_type = 'Issue' AND e.action = #{Event::CLOSED}")
            .where(milestone: @milestone)
            .where("state = 'closed' OR (state = 'opened' AND e.action = #{Event::CLOSED})") # rubocop:disable GitlabSecurity/SqlInjection

        rel =
          if Gitlab::Database.postgresql?
            ::Issue
              .select("*")
              .from(internal_clause.select('DISTINCT ON (issues.id) issues.id, issues.state, issues.weight, e.created_at AS closed_at'))
              .order('closed_at ASC')
              .pluck('closed_at, weight, state')
          else
            # In rails 5 mysql's `only_full_group_by` option is enabled by default,
            # this means that `GROUP` clause must include all columns used in `SELECT`
            # clause. Adding all columns to `GROUP` means that we have now
            # duplicates (by issue ID) in records. To get rid of these, we unify them
            # on ruby side by issue id. Finally we drop the issue id attribute from records
            # because this is not accepted when creating Issue object.
            ::Issue
              .select("*")
              .from(internal_clause.select('issues.id, issues.state, issues.weight, e.created_at AS closed_at'))
              .group(:id, :closed_at, :weight, :state)
              .having('closed_at = MIN(closed_at) OR closed_at IS NULL')
              .order('closed_at ASC')
              .pluck('id, closed_at, weight, state')
              .uniq(&:first)
              .map { |attrs| attrs.drop(1) }
          end

        rel.map { |attrs| Issue.new(*attrs) }
      end
  end
end
