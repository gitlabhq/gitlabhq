# frozen_string_literal: true

class CreatePartitionsForAuditEventTables < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  FROM_TO_REGEXP = /FOR VALUES FROM \('?(?<from>.+)'?\) TO \('?(?<to>.+)'?\)/

  def up
    partitions = current_partitions

    max_date = Date.today.next_month.beginning_of_month
    min_date = find_min_date(partitions.to_a)

    drop_partitions(:user_audit_events)
    drop_partitions(:group_audit_events)
    drop_partitions(:project_audit_events)
    drop_partitions(:instance_audit_events)
    create_daterange_partitions(:user_audit_events, "created_at", min_date, max_date)
    create_daterange_partitions(:group_audit_events, "created_at", min_date, max_date)
    create_daterange_partitions(:project_audit_events, "created_at", min_date, max_date)
    create_daterange_partitions(:instance_audit_events, "created_at", min_date, max_date)
  end

  def down
    drop_partitions(:user_audit_events)
    drop_partitions(:group_audit_events)
    drop_partitions(:project_audit_events)
    drop_partitions(:instance_audit_events)
  end

  private

  def current_partitions
    execute <<~SQL
      SELECT *
      FROM postgres_partitions
      WHERE parent_identifier = (SELECT current_schema() || '.audit_events');
    SQL
  end

  def find_min_date(partitions)
    minvalue_record = partitions.find { |partition| partition["condition"].include?('MINVALUE') }

    if minvalue_record
      matches = minvalue_record["condition"].match(FROM_TO_REGEXP)
      matches[:to].to_date
    else
      Date.today.beginning_of_month
    end
  end

  def drop_partitions(table_name)
    result = execute <<-SQL
              SELECT * FROM postgres_partitions
               WHERE parent_identifier = (SELECT current_schema() || '.#{table_name}');
    SQL

    result.to_a.each do |partition|
      execute("DROP TABLE #{partition['identifier']}")
    end
  end
end
