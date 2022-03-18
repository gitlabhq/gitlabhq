# frozen_string_literal: true

class RemoveDuplicateProjectAuthorizations < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  BATCH_SIZE = 10_000
  OLD_INDEX_NAME = 'index_project_authorizations_on_project_id_user_id'
  INDEX_NAME = 'index_unique_project_authorizations_on_project_id_user_id'

  class ProjectAuthorization < ActiveRecord::Base
    self.table_name = 'project_authorizations'
  end

  disable_ddl_transaction!

  def up
    batch do |first_record, last_record|
      break if first_record.blank?

      # construct a range query where we filter records between the first and last records
      rows = ActiveRecord::Base.connection.execute <<~SQL
        SELECT user_id, project_id
        FROM project_authorizations
        WHERE
        #{start_condition(first_record)}
        #{end_condition(last_record)}
        GROUP BY user_id, project_id
        HAVING COUNT(*) > 1
      SQL

      rows.each do |row|
        deduplicate_item(row['project_id'], row['user_id'])
      end
    end

    add_concurrent_index :project_authorizations, [:project_id, :user_id], unique: true, name: INDEX_NAME
    remove_concurrent_index_by_name :project_authorizations, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index(:project_authorizations, [:project_id, :user_id], name: OLD_INDEX_NAME)
    remove_concurrent_index_by_name(:project_authorizations, INDEX_NAME)
  end

  private

  def start_condition(record)
    "(user_id, project_id) >= (#{Integer(record.user_id)}, #{Integer(record.project_id)})"
  end

  def end_condition(record)
    return "" unless record

    "AND (user_id, project_id) <= (#{Integer(record.user_id)}, #{Integer(record.project_id)})"
  end

  def batch(&block)
    order = Gitlab::Pagination::Keyset::Order.build([
        Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
          attribute_name: 'user_id',
          order_expression: ProjectAuthorization.arel_table[:user_id].asc,
          nullable: :not_nullable,
          distinct: false
        ),
        Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
          attribute_name: 'project_id',
          order_expression: ProjectAuthorization.arel_table[:project_id].asc,
          nullable: :not_nullable,
          distinct: false
        ),
        Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
          attribute_name: 'access_level',
          order_expression: ProjectAuthorization.arel_table[:access_level].asc,
          nullable: :not_nullable,
          distinct: true
        )
      ])

    scope = ProjectAuthorization.order(order)
    cursor = {}
    loop do
      current_scope = scope.dup

      relation = order.apply_cursor_conditions(current_scope, cursor)
      first_record = relation.take
      last_record = relation.offset(BATCH_SIZE).take

      yield first_record, last_record

      break if last_record.blank?

      cursor = order.cursor_attributes_for_node(last_record)
    end
  end

  def deduplicate_item(project_id, user_id)
    auth_records = ProjectAuthorization.where(project_id: project_id, user_id: user_id).order(access_level: :desc).to_a

    ActiveRecord::Base.transaction do
      # Keep the highest access level and destroy the rest.
      auth_records[1..].each do |record|
        ProjectAuthorization
        .where(
          project_id: record.project_id,
          user_id: record.user_id,
          access_level: record.access_level
        ).delete_all
      end
    end
  end
end
