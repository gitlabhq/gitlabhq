# frozen_string_literal: true

module MergeRequests
  # StackFinder discovers merge request stacks: chains of merge requests where
  # each merge request targets the source branch of the merge request above it.
  #
  # Example stack:
  #   merge_request_1: source_branch=feature-1, target_branch=main
  #   merge_request_2: source_branch=feature-2, target_branch=feature-1
  #   merge_request_3: source_branch=feature-3, target_branch=feature-2
  #
  # Given any merge request in the stack, #execute returns
  # [merge_request_1, merge_request_2, merge_request_3] ordered from top
  # (closest to the default branch) to bottom.
  #
  # Only open merge requests are traversed. The input merge request is always
  # included. Authorization is the caller's responsibility.
  #
  # Branch chaining is a tree, not a line: if two MRs share the same
  # target_branch, both could be considered part of a stack. This finder
  # follows a single deterministic path - when multiple MRs branch from the
  # same target, the one with the lowest id (oldest) is followed; sibling
  # forks are not surfaced.
  class StackFinder
    MAX_STACK_SIZE = 10

    # Two unidirectional recursive CTEs.
    #
    # A single bidirectional CTE causes exponential path explosion: each worktable
    # row spawns up to 2 new rows (one parent, one child), so row count doubles per
    # level. Splitting into two linear CTEs keeps total rows at most 2 x MAX_STACK_SIZE.
    #
    # The up_chain lateral uses the composite (target_project_id, source_branch) index.
    # The down_chain lateral uses a BitmapAnd on (target_branch) + (target_project_id,
    # state_id), which is safe because source_branch values are unique feature branch
    # names - never common names like 'main' that would produce many global index hits.
    #
    # The upward chain stops when it reaches the default branch - without this, common
    # branch names cause false matches that chain through unrelated merge requests.
    STACK_CTE_SQL = <<~SQL
      WITH RECURSIVE
      up_chain(id, source_branch, target_branch, visited) AS (
        SELECT id, source_branch, target_branch, ARRAY[id]
        FROM merge_requests
        WHERE id = :merge_request_id
          AND state_id = 1

        UNION ALL

        SELECT p.id, p.source_branch, p.target_branch, up_chain.visited || p.id
        FROM up_chain
        CROSS JOIN LATERAL (
          -- oldest id wins when multiple MRs share the same source branch
          SELECT id, source_branch, target_branch
          FROM merge_requests
          WHERE target_project_id = :project_id
            AND state_id = 1
            AND source_branch = up_chain.target_branch
            AND NOT (id = ANY(up_chain.visited))
          ORDER BY id
          LIMIT 1
        ) p
        WHERE array_length(up_chain.visited, 1) < :max_size
          AND up_chain.target_branch != :default_branch
      ),
      down_chain(id, source_branch, target_branch, visited) AS (
        SELECT id, source_branch, target_branch, ARRAY[id]
        FROM merge_requests
        WHERE id = :merge_request_id
          AND state_id = 1

        UNION ALL

        SELECT c.id, c.source_branch, c.target_branch, down_chain.visited || c.id
        FROM down_chain
        CROSS JOIN LATERAL (
          -- oldest id wins when multiple MRs target the same branch
          SELECT id, source_branch, target_branch
          FROM merge_requests
          WHERE target_project_id = :project_id
            AND state_id = 1
            AND target_branch = down_chain.source_branch
            AND NOT (id = ANY(down_chain.visited))
          ORDER BY id
          LIMIT 1
        ) c
        WHERE array_length(down_chain.visited, 1) < :max_size
      )
      SELECT merge_requests.*
      FROM merge_requests
      INNER JOIN (
        SELECT id FROM up_chain
        UNION
        SELECT id FROM down_chain
      ) stack_ids ON stack_ids.id = merge_requests.id
    SQL

    def initialize(current_user, merge_request)
      @current_user = current_user
      @merge_request = merge_request
      @project = merge_request.target_project
    end

    def execute
      return MergeRequest.none unless adjacent_merge_request_exists?

      rows = stack_rows
      return MergeRequest.none if rows.size <= 1

      ordered_ids = sort_by_chain(rows).map(&:id)
      MergeRequest.id_in(ordered_ids).in_order_of(:id, ordered_ids)
    end

    private

    attr_reader :current_user, :merge_request, :project

    def adjacent_merge_request_exists?
      base = MergeRequest.of_projects(project.id).opened.id_not_in(merge_request.id)

      base.by_source_branch(merge_request.target_branch)
          .or(base.by_target_branch(merge_request.source_branch))
          .exists?
    end

    # rubocop: disable CodeReuse/ActiveRecord -- find_by_sql required for recursive CTE
    def stack_rows
      MergeRequest.find_by_sql([
        STACK_CTE_SQL,
        {
          merge_request_id: merge_request.id,
          project_id: project.id,
          max_size: MAX_STACK_SIZE,
          default_branch: project.default_branch
        }
      ])
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # Orders the loaded merge request records by following the branch chain from
    # the root. The root is the merge request whose target_branch is not the
    # source_branch of any other merge request in the set (i.e. nothing in the
    # stack points to it as a child).
    def sort_by_chain(rows)
      source_branches = rows.map(&:source_branch).to_set
      root_row = rows.find { |r| source_branches.exclude?(r.target_branch) }
      return rows if root_row.nil?

      by_target_branch = rows.index_by(&:target_branch)
      seen = Set.new
      result = []

      current_row = root_row
      while current_row && seen.add?(current_row.id)
        result << current_row
        current_row = by_target_branch[current_row.source_branch]
      end

      result
    end
  end
end
