# frozen_string_literal: true

class CreateCiBuilds100Views < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  VIEW_PREFIX = 'gitlab_partitions_dynamic.ci_builds_views_100'
  VIEW_BOUNDARIES = [
    1,
    1500384395,
    2951960143,
    4355055910,
    12168556334
  ].freeze

  def up
    return unless Gitlab.com_except_jh?

    view_ranges.each_with_index do |range, index|
      create_view(index + 1, range)
    end
  end

  def down
    view_ranges.each_with_index do |_, index|
      execute("DROP VIEW IF EXISTS #{VIEW_PREFIX}_#{index + 1};")
    end
  end

  private

  def view_ranges
    VIEW_BOUNDARIES.each_cons(2).map { |lower, upper| (lower..upper) }
  end

  def create_view(view_number, range)
    execute(<<~SQL.squish)
      CREATE OR REPLACE VIEW #{VIEW_PREFIX}_#{view_number} AS
      SELECT id, partition_id
      FROM p_ci_builds
      WHERE id >= #{range.min} AND id < #{range.max} AND partition_id = 100
    SQL
  end
end
