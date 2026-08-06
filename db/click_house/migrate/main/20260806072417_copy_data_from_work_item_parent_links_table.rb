# frozen_string_literal: true

class CopyDataFromWorkItemParentLinksTable < ClickHouse::Migration
  BATCH_SIZE = 500_000

  COLUMNS = %i[
    id
    work_item_id
    work_item_parent_id
    relative_position
    created_at
    updated_at
    namespace_id
    traversal_path
    _siphon_replicated_at
    _siphon_deleted
  ].freeze

  def up
    builder = ClickHouse::Client::QueryBuilder.new('siphon_work_item_parent_links')
    iterator = ClickHouse::Iterator.new(query_builder: builder, connection: connection)

    iterator.each_batch(column: :id, of: BATCH_SIZE) do |scope|
      execute("INSERT INTO siphon_work_item_parent_links_tmp (#{COLUMNS.join(', ')}) #{scope.select(*COLUMNS).to_sql}")
    end
  end

  def down
    # no-op
  end
end
