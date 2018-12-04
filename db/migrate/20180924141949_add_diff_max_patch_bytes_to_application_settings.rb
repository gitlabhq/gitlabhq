# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddDiffMaxPatchBytesToApplicationSettings < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:application_settings,
                            :diff_max_patch_bytes,
                            :integer,
                            default: 100.kilobytes,
                            allow_null: false)
  end

  def down
    remove_column(:application_settings, :diff_max_patch_bytes)
  end
end
