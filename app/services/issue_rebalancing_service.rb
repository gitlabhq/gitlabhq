# frozen_string_literal: true

class IssueRebalancingService
  MAX_ISSUE_COUNT = 10_000
  BATCH_SIZE = 100
  SMALLEST_BATCH_SIZE = 5
  RETRIES_LIMIT = 3
  TooManyIssues = Class.new(StandardError)

  TIMING_CONFIGURATION = [
    [0.1.seconds, 0.05.seconds], # short timings, lock_timeout: 100ms, sleep after LockWaitTimeout: 50ms
    [0.5.seconds, 0.05.seconds],
    [1.second, 0.5.seconds],
    [1.second, 0.5.seconds],
    [5.seconds, 1.second]
  ].freeze

  def initialize(projects_collection)
    @root_namespace = projects_collection.take.root_namespace # rubocop:disable CodeReuse/ActiveRecord
    @base = Issue.in_projects(projects_collection)
  end

  def execute
    return unless Feature.enabled?(:rebalance_issues, root_namespace)

    raise TooManyIssues, "#{issue_count} issues" if issue_count > MAX_ISSUE_COUNT

    start = RelativePositioning::START_POSITION - (gaps / 2) * gap_size

    if Feature.enabled?(:issue_rebalancing_optimization)
      Issue.transaction do
        assign_positions(start, indexed_ids)
          .sort_by(&:first)
          .each_slice(BATCH_SIZE) do |pairs_with_position|
          if Feature.enabled?(:issue_rebalancing_with_retry)
            update_positions_with_retry(pairs_with_position, 'rebalance issue positions in batches ordered by id')
          else
            update_positions(pairs_with_position, 'rebalance issue positions in batches ordered by id')
          end
        end
      end
    else
      Issue.transaction do
        indexed_ids.each_slice(BATCH_SIZE) do |pairs|
          pairs_with_position = assign_positions(start, pairs)

          if Feature.enabled?(:issue_rebalancing_with_retry)
            update_positions_with_retry(pairs_with_position, 'rebalance issue positions')
          else
            update_positions(pairs_with_position, 'rebalance issue positions')
          end
        end
      end
    end
  end

  private

  attr_reader :root_namespace, :base

  # rubocop: disable CodeReuse/ActiveRecord
  def indexed_ids
    base.reorder(:relative_position, :id).pluck(:id).each_with_index
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def assign_positions(start, pairs)
    pairs.map do |id, index|
      [id, start + (index * gap_size)]
    end
  end

  def update_positions_with_retry(pairs_with_position, query_name)
    retries = 0
    batch_size = pairs_with_position.size

    until pairs_with_position.empty?
      begin
        update_positions(pairs_with_position.first(batch_size), query_name)
        pairs_with_position = pairs_with_position.drop(batch_size)
        retries = 0
      rescue ActiveRecord::StatementTimeout, ActiveRecord::QueryCanceled => ex
        raise ex if batch_size < SMALLEST_BATCH_SIZE

        if (retries += 1) == RETRIES_LIMIT
          # shrink the batch size in half when RETRIES limit is reached and update still fails perhaps because batch size is still too big
          batch_size = (batch_size / 2).to_i
          retries = 0
        end

        retry
      end
    end
  end

  def update_positions(pairs_with_position, query_name)
    values = pairs_with_position.map do |id, index|
      "(#{id}, #{index})"
    end.join(', ')

    Gitlab::Database::WithLockRetries.new(timing_configuration: TIMING_CONFIGURATION, klass: self.class).run do
      run_update_query(values, query_name)
    end
  end

  def run_update_query(values, query_name)
    Issue.connection.exec_query(<<~SQL, query_name)
      WITH cte(cte_id, new_pos) AS #{Gitlab::Database::AsWithMaterialized.materialized_if_supported} (
       SELECT *
       FROM (VALUES #{values}) as t (id, pos)
      )
      UPDATE #{Issue.table_name}
      SET relative_position = cte.new_pos
      FROM cte
      WHERE cte_id = id
    SQL
  end

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
