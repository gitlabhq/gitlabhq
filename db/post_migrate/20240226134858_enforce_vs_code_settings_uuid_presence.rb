# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class EnforceVsCodeSettingsUuidPresence < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.10'

  def up
    add_not_null_constraint :vs_code_settings, :uuid
  end

  def down
    remove_not_null_constraint :vs_code_settings, :uuid
  end
end
