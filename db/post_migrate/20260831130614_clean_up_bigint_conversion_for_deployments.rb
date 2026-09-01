# frozen_string_literal: true

class CleanUpBigintConversionForDeployments < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  milestone '19.4'

  TABLE = :deployments
  COLUMNS = %i[id environment_id project_id user_id].freeze

  def up
    return unless can_execute_on?(TABLE)

    cleanup_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    # no-op
  end
end
