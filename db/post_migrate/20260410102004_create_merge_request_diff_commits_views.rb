# frozen_string_literal: true

class CreateMergeRequestDiffCommitsViews < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  VIEW_PREFIX = 'merge_request_diff_commits_views'

  # Lower bounds of each view as composite cursors [merge_request_diff_id, relative_order].
  # View N covers [(LOWER_BOUNDS[N-1]), (LOWER_BOUNDS[N])), with the last view open-ended.
  # Bounds use the composite key (merge_request_diff_id, relative_order) to match the cursor structure
  # used by the iterator
  VIEW_LOWER_BOUNDS = [
    [0, 0],
    [405_423_843, 0],
    [1_010_436_901, 0],
    [1_224_788_900, 0]
  ].freeze

  def up
    return unless Gitlab.com_except_jh?

    view_ranges.each_with_index do |range, index|
      create_view(index + 1, range)
    end
  end

  def down
    return unless Gitlab.com_except_jh?

    VIEW_LOWER_BOUNDS.each_with_index do |_, index|
      execute("DROP VIEW IF EXISTS #{VIEW_PREFIX}_#{index + 1};")
    end
  end

  private

  def view_ranges
    VIEW_LOWER_BOUNDS.each_with_index.map do |lower, i|
      [lower, VIEW_LOWER_BOUNDS[i + 1]] # upper is nil for the last (open-ended) view
    end
  end

  def create_view(view_number, range)
    lower, upper = range
    upper_clause = upper ? "AND (merge_request_diff_id, relative_order) < (#{upper[0]}, #{upper[1]})" : ""

    execute(<<~SQL.squish)
      CREATE OR REPLACE VIEW #{VIEW_PREFIX}_#{view_number} AS
      SELECT merge_request_diff_id, relative_order
      FROM merge_request_diff_commits
      WHERE (merge_request_diff_id, relative_order) >= (#{lower[0]}, #{lower[1]})
      #{upper_clause}
    SQL
  end
end
