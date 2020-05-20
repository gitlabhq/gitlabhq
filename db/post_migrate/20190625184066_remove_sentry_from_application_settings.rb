# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveSentryFromApplicationSettings < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  SENTRY_ENABLED_COLUMNS = [
    :sentry_enabled,
    :clientside_sentry_enabled
  ].freeze

  SENTRY_DSN_COLUMNS = [
    :sentry_dsn,
    :clientside_sentry_dsn
  ].freeze

  disable_ddl_transaction!

  def up
    (SENTRY_ENABLED_COLUMNS + SENTRY_DSN_COLUMNS).each do |column|
      remove_column(:application_settings, column) if column_exists?(:application_settings, column)
    end
  end

  def down
    SENTRY_ENABLED_COLUMNS.each do |column|
      # rubocop:disable Migration/AddColumnWithDefault
      add_column_with_default(:application_settings, column, :boolean, default: false, allow_null: false) unless column_exists?(:application_settings, column)
      # rubocop:enable Migration/AddColumnWithDefault
    end

    SENTRY_DSN_COLUMNS.each do |column|
      add_column(:application_settings, column, :string) unless column_exists?(:application_settings, column)
    end
  end
end
