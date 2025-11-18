# frozen_string_literal: true

class UpdatePartitioningThresholdTo500Gb < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '18.6'

  def up
    return unless Gitlab.com_except_jh?

    update_partitioning_threshold(500.gigabytes)
  end

  def down
    return unless Gitlab.com_except_jh?

    update_partitioning_threshold(1.terabyte)
  end

  private

  def update_partitioning_threshold(size)
    execute(<<~SQL.squish)
      UPDATE application_settings
      SET ci_cd_settings = jsonb_set(
        ci_cd_settings, '{ci_partitions_size_limit}', to_jsonb(#{size})
      )
    SQL
  end
end
