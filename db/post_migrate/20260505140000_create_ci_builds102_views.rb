# frozen_string_literal: true

class CreateCiBuilds102Views < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  VIEW_PREFIX = 'gitlab_partitions_dynamic.ci_builds_views_102'

  def up
    return unless Gitlab.com_except_jh?

    create_view(1, 7126747017..9345589511)
    create_view(2, 9345589511..12168598399)
  end

  def down
    execute("DROP VIEW IF EXISTS #{VIEW_PREFIX}_1;")
    execute("DROP VIEW IF EXISTS #{VIEW_PREFIX}_2;")
  end

  private

  def create_view(view_number, range)
    execute(<<~SQL.squish)
      CREATE OR REPLACE VIEW #{VIEW_PREFIX}_#{view_number} AS
      SELECT id, partition_id
      FROM p_ci_builds
      WHERE id >= #{range.min} AND id < #{range.max} AND partition_id = 102
    SQL
  end
end
