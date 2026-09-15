# frozen_string_literal: true

# Queues validation after all replacement bigint foreign keys exist in production.
class PrepareAsyncValidationForDeploymentMergeRequestsBigintFks < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  TABLE_NAME = :deployment_merge_requests
  FOREIGN_KEYS = {
    deployment_id_convert_to_bigint: :fk_rails_dcbce9f4df_tmp,
    merge_request_id_convert_to_bigint: :fk_rails_86a6d8bf12_tmp,
    environment_id_convert_to_bigint: :fk_a064ff4453_tmp
  }.freeze

  def up
    return unless FOREIGN_KEYS.all? { |column, _| column_exists?(TABLE_NAME, column) }

    FOREIGN_KEYS.each do |column, name|
      prepare_async_foreign_key_validation(TABLE_NAME, column, name: name)
    end
  end

  def down
    return unless FOREIGN_KEYS.all? { |column, _| column_exists?(TABLE_NAME, column) }

    FOREIGN_KEYS.each do |column, name|
      unprepare_async_foreign_key_validation(TABLE_NAME, column, name: name)
    end
  end
end
