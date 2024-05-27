# frozen_string_literal: true

module Issues
  class RelativePositionRebalancingService
    UPDATE_BATCH_SIZE = 100
    PREFETCH_ISSUES_BATCH_SIZE = 10_000
    SMALLEST_BATCH_SIZE = 5
    RETRIES_LIMIT = 3

    TooManyConcurrentRebalances = Class.new(StandardError)

    def initialize(projects)
      @projects_collection = (projects.is_a?(Array) ? Project.id_in(projects) : projects).select(:id).projects_order_id_asc
      @root_namespace = @projects_collection.select(:namespace_id).reorder(nil).take.root_namespace # rubocop:disable CodeReuse/ActiveRecord
      @caching = ::Gitlab::Issues::Rebalancing::State.new(@root_namespace, @projects_collection)
    end

    def execute
      # Given can_start_rebalance? and track_new_running_rebalance are not atomic
      # it can happen that we end up with more than Rebalancing::State::MAX_NUMBER_OF_CONCURRENT_REBALANCES running.
      # Considering the number of allowed Rebalancing::State::MAX_NUMBER_OF_CONCURRENT_REBALANCES is small we should be ok,
      # but should be something to consider if we'd want to scale this up.
      error_message = "#{caching.concurrent_running_rebalances_count} concurrent re-balances currently running"
      raise TooManyConcurrentRebalances, error_message unless caching.can_start_rebalance?

      block_issue_repositioning! unless root_namespace.issue_repositioning_disabled?
      caching.track_new_running_rebalance
      index = caching.get_current_index

      loop do
        issue_ids = get_issue_ids(index, PREFETCH_ISSUES_BATCH_SIZE)
        pairs_with_index = assign_indexes(issue_ids, index)

        pairs_with_index.each_slice(UPDATE_BATCH_SIZE) do |pairs_batch|
          update_positions_with_retry(pairs_batch, 're-balance issue positions in batches ordered by position')
        end

        index = caching.get_current_index

        break if index >= caching.issue_count - 1
      end

      caching.cleanup_cache
      unblock_issue_repositioning!
    end

    private

    attr_reader :root_namespace, :projects_collection, :caching

    def block_issue_repositioning!
      Feature.enable(:block_issue_repositioning, root_namespace)
    end

    def unblock_issue_repositioning!
      Feature.disable(:block_issue_repositioning, root_namespace)
    end

    def get_issue_ids(index, limit)
      issue_ids = caching.get_cached_issue_ids(index, limit)

      # if we have a list of cached issues and no current project id cached,
      # then we successfully cached issues for all projects
      return issue_ids if issue_ids.any? && caching.get_current_project_id.blank?

      # if we got no issue ids at the start of re-balancing then we did not cache any issue ids yet
      preload_issue_ids

      caching.get_cached_issue_ids(index, limit)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def preload_issue_ids
      index = 0
      cached_project_id = caching.get_current_project_id

      collection = projects_collection
      collection = projects_collection.where(Project.arel_table[:id].gteq(cached_project_id.to_i)) if cached_project_id.present?

      collection.each do |project|
        caching.cache_current_project_id(project.id)
        index += 1
        scope = Issue.in_projects(project).order_by_relative_position.with_non_null_relative_position.select(:id, :relative_position)

        with_retry(PREFETCH_ISSUES_BATCH_SIZE, 100) do |batch_size|
          Gitlab::Pagination::Keyset::Iterator.new(scope: scope).each_batch(of: batch_size) do |batch|
            caching.cache_issue_ids(batch)
          end
        end
      end

      caching.remove_current_project_id_cache
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def assign_indexes(ids, start_index)
      ids.each_with_index.map do |id, idx|
        [id, start_index + idx]
      end
    end

    # The method runs in a loop where we try for RETRIES_LIMIT=3 times, to run the update statement on
    # a number of records(batch size). Method gets an array of (id, value) pairs as argument that is used
    # to build the update query matching by id and updating relative_position = value. If we get a statement
    # timeout, we split the batch size in half and try(for 3 times again) to batch update on a smaller number of records.
    # On success, because we know the batch size and we always pick from the beginning of the array param,
    # we can remove first batch_size number of items from array and continue with the successful batch_size for next batches.
    # On failures we continue to split batch size to a SMALLEST_BATCH_SIZE limit, which is now set at 5.
    #
    # e.g.
    # 0. items | previous batch size|new batch size | comment
    # 1. 100   | 100                | 100           | 3 failures -> split the batch size in half
    # 2. 100   | 100                | 50            | 3 failures -> split the batch size in half again
    # 3. 100   | 50                 | 25            | 3 succeed -> so we drop 25 items 3 times, 4th fails -> split the batch size in half again
    # 5. 25    | 25                 | 12            | 3 failures -> split the batch size in half
    # 6. 25    | 12                 | 6             | 3 failures -> we exit because smallest batch size is 5 and we'll be at 3 if we split again

    def update_positions_with_retry(pairs_with_index, query_name)
      retry_batch_size = pairs_with_index.size

      until pairs_with_index.empty?
        with_retry(retry_batch_size, SMALLEST_BATCH_SIZE) do |batch_size|
          retry_batch_size = batch_size
          update_positions(pairs_with_index.first(batch_size), query_name)
          # pairs_with_index[batch_size - 1] - can be nil for last batch
          # if last batch is smaller than batch_size, so we just get the last pair.
          last_pair_in_batch = pairs_with_index[batch_size - 1] || pairs_with_index.last
          caching.cache_current_index(last_pair_in_batch.last + 1)
          pairs_with_index = pairs_with_index.drop(batch_size)
        end
      end
    end

    def update_positions(pairs_with_position, query_name)
      values = pairs_with_position.map do |id, index|
        "(#{id}, #{start_position + (index * gap_size)})"
      end.join(', ')

      run_update_query(values, query_name)
    end

    def run_update_query(values, query_name)
      Issue.connection.exec_query(<<~SQL, query_name)
        WITH cte(cte_id, new_pos) AS MATERIALIZED (
         SELECT *
         FROM (VALUES #{values}) as t (id, pos)
        )
        UPDATE #{Issue.table_name}
        SET relative_position = cte.new_pos
        FROM cte
        WHERE cte_id = id
      SQL
    end

    def gaps
      caching.issue_count - 1
    end

    def gap_size
      RelativePositioning::MAX_GAP
    end

    def start_position
      @start_position ||= (RelativePositioning::START_POSITION - ((gaps / 2) * gap_size)).to_i
    end

    def with_retry(initial_batch_size, exit_batch_size)
      retries = 0
      batch_size = initial_batch_size

      begin
        yield batch_size
        retries = 0
      rescue ActiveRecord::StatementTimeout, ActiveRecord::QueryCanceled => ex
        raise ex if batch_size < exit_batch_size

        if (retries += 1) == RETRIES_LIMIT
          # shrink the batch size in half when RETRIES limit is reached and update still fails perhaps because batch size is still too big
          batch_size = (batch_size / 2).to_i
          retries = 0
        end

        retry
      end
    end
  end
end
