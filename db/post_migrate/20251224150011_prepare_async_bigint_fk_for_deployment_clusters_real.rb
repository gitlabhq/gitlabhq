# frozen_string_literal: true

class PrepareAsyncBigintFkForDeploymentClustersReal < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  TABLE_NAME = 'deployment_clusters'
  COLUMNS = %i[deployment_id].freeze

  def up
    conversion_needed = COLUMNS.all? do |column|
      column_exists?(TABLE_NAME, convert_to_bigint_column(column))
    end

    unless conversion_needed
      say "No conversion columns found - no need to validate bigint FKs"
      return
    end

    prepare_async_foreign_key_validation(:deployment_clusters, :deployment_id_convert_to_bigint,
      name: :fk_rails_6359a164df_tmp)
  end

  def down
    conversion_needed = COLUMNS.all? do |column|
      column_exists?(TABLE_NAME, convert_to_bigint_column(column))
    end

    unless conversion_needed
      say "No conversion columns found - no need to validate bigint FKs"
      return
    end

    unprepare_async_foreign_key_validation(:deployment_clusters, :deployment_id_convert_to_bigint,
      name: :fk_rails_6359a164df_tmp)
  end
end
