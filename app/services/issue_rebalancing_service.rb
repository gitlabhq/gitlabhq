# frozen_string_literal: true

class IssueRebalancingService
  MAX_ISSUE_COUNT = 10_000
  TooManyIssues = Class.new(StandardError)

  def initialize(issue)
    @issue = issue
    @base = Issue.relative_positioning_query_base(issue)
  end

  def execute
    gates = [issue.project, issue.project.group].compact
    return unless gates.any? { |gate| Feature.enabled?(:rebalance_issues, gate) }

    raise TooManyIssues, "#{issue_count} issues" if issue_count > MAX_ISSUE_COUNT

    start = RelativePositioning::START_POSITION - (gaps / 2) * gap_size

    Issue.transaction do
      indexed_ids.each_slice(100) { |pairs| assign_positions(start, pairs) }
    end
  end

  private

  attr_reader :issue, :base

  # rubocop: disable CodeReuse/ActiveRecord
  def indexed_ids
    base.reorder(:relative_position, :id).pluck(:id).each_with_index
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def assign_positions(start, positions)
    values = positions.map do |id, index|
      "(#{id}, #{start + (index * gap_size)})"
    end.join(', ')

    Issue.connection.exec_query(<<~SQL, "rebalance issue positions")
      WITH cte(cte_id, new_pos) AS (
       SELECT *
       FROM (VALUES #{values}) as t (id, pos)
      )
      UPDATE #{Issue.table_name}
      SET relative_position = cte.new_pos
      FROM cte
      WHERE cte_id = id
    SQL
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def issue_count
    @issue_count ||= base.count
  end

  def gaps
    issue_count - 1
  end

  def gap_size
    # We could try to split the available range over the number of gaps we need,
    # but IDEAL_DISTANCE * MAX_ISSUE_COUNT is only 0.1% of the available range,
    # so we are guaranteed not to exhaust it by using this static value.
    #
    # If we raise MAX_ISSUE_COUNT or IDEAL_DISTANCE significantly, this may
    # change!
    RelativePositioning::IDEAL_DISTANCE
  end
end
