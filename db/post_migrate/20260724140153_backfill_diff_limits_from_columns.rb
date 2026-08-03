# frozen_string_literal: true

class BackfillDiffLimitsFromColumns < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    execute <<~SQL
      UPDATE application_settings
      SET diff_limits = COALESCE(diff_limits, '{}'::jsonb) ||
        jsonb_build_object(
          'diff_max_patch_bytes', diff_max_patch_bytes,
          'diff_max_files', diff_max_files,
          'diff_max_lines', diff_max_lines
        )
    SQL
  end

  def down
    execute <<~SQL
      UPDATE application_settings
      SET diff_limits = diff_limits - 'diff_max_patch_bytes' - 'diff_max_files' - 'diff_max_lines'
    SQL
  end
end
