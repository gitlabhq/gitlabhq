# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class UpdateDefaultScanMethodOfDastSiteProfile < Gitlab::Database::Migration[1.0]
  BATCH_SIZE = 500

  disable_ddl_transaction!

  def up
    each_batch_range('dast_site_profiles', scope: ->(table) { table.where(target_type: 1) }, of: BATCH_SIZE) do |min, max|
      execute <<~SQL
        UPDATE dast_site_profiles
        SET scan_method = 1
        WHERE id BETWEEN #{min} AND #{max}
      SQL
    end
  end

  def down
    # noop
  end
end
