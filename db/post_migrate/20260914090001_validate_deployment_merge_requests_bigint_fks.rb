# frozen_string_literal: true

class ValidateDeploymentMergeRequestsBigintFks < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!
  milestone '19.5'

  TABLE_NAME = 'deployment_merge_requests'
  COLUMNS = %w[deployment_id merge_request_id environment_id].freeze
  FOREIGN_KEYS = {
    deployment_id_convert_to_bigint: 'fk_rails_dcbce9f4df_tmp',
    merge_request_id_convert_to_bigint: 'fk_rails_86a6d8bf12_tmp',
    environment_id_convert_to_bigint: 'fk_a064ff4453_tmp'
  }.freeze

  def up
    return if skip_bigint_migration?(TABLE_NAME, COLUMNS)

    FOREIGN_KEYS.each do |column, name|
      validate_foreign_key(TABLE_NAME, column, name: name)
    end
  end

  def down
    # no-op
  end
end
