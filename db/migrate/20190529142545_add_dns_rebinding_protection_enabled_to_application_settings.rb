# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddDnsRebindingProtectionEnabledToApplicationSettings < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:application_settings, :dns_rebinding_protection_enabled, # rubocop:disable Migration/AddColumnWithDefault
                            :boolean,
                            default: true,
                            allow_null: false)
  end

  def down
    remove_column(:application_settings, :dns_rebinding_protection_enabled)
  end
end
