# frozen_string_literal: true

class LooseForeignKeys::DeletedRecord < ApplicationRecord
  extend SuppressCompositePrimaryKeyWarning
  include PartitionedTable

  partitioned_by :created_at, strategy: :monthly, retain_for: 3.months, retain_non_empty_partitions: true

  scope :ordered_by_primary_keys, -> { order(:created_at, :deleted_table_name, :deleted_table_primary_key_value) }

  def self.load_batch(batch_size)
    ordered_by_primary_keys
      .limit(batch_size)
      .to_a
  end

  # Because the table has composite primary keys, the delete_all or delete methods are not going to work.
  # This method implements deletion that benefits from the primary key index, example:
  #
  # > DELETE
  # > FROM "loose_foreign_keys_deleted_records"
  # > WHERE (created_at,
  # >        deleted_table_name,
  # >        deleted_table_primary_key_value) IN
  # >     (SELECT created_at::TIMESTAMP WITH TIME ZONE,
  # >                                             deleted_table_name,
  # >                                             deleted_table_primary_key_value
  # >      FROM (VALUES (LIST_OF_VALUES)) AS primary_key_values (created_at, deleted_table_name, deleted_table_primary_key_value))
  def self.delete_records(records)
    values = records.pluck(:created_at, :deleted_table_name, :deleted_table_primary_key_value)

    primary_keys = connection.primary_keys(table_name).join(', ')

    primary_keys_with_type_cast = [
      Arel.sql('created_at::timestamp with time zone'),
      Arel.sql('deleted_table_name'),
      Arel.sql('deleted_table_primary_key_value')
    ]

    value_list = Arel::Nodes::ValuesList.new(values)

    # (SELECT primary keys FROM VALUES)
    inner_query = Arel::SelectManager.new
    inner_query.from("#{Arel::Nodes::Grouping.new([value_list]).as('primary_key_values').to_sql} (#{primary_keys})")
    inner_query.projections = primary_keys_with_type_cast

    where(Arel::Nodes::Grouping.new([Arel.sql(primary_keys)]).in(inner_query)).delete_all
  end
end
