# frozen_string_literal: true

class AddBigintFkForDeploymentClustersReal < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.8'

  TABLE_NAME = 'deployment_clusters'
  COLUMNS = %i[deployment_id cluster_id].freeze
  FOREIGN_KEYS = [
    {
      source_table: :deployment_clusters,
      column: :deployment_id_convert_to_bigint,
      target_table: :deployments,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      tmp_name: :fk_rails_6359a164df_tmp
    }
  ].freeze

  def up
    conversion_needed = COLUMNS.all? do |column|
      column_exists?(TABLE_NAME, convert_to_bigint_column(column))
    end

    unless conversion_needed
      say "No conversion columns found - no need to create bigint FKs"
      return
    end

    FOREIGN_KEYS.each do |fk|
      add_concurrent_foreign_key(
        fk[:source_table],
        fk[:target_table],
        column: fk[:column],
        target_column: fk[:target_column],
        name: fk[:tmp_name],
        on_delete: fk[:on_delete],
        validate: false,
        reverse_lock_order: true
      )
    end
  end

  def down
    FOREIGN_KEYS.each do |fk|
      remove_foreign_key_if_exists(
        fk[:source_table],
        fk[:target_table],
        name: fk[:tmp_name],
        reverse_lock_order: true
      )
    end
  end
end
