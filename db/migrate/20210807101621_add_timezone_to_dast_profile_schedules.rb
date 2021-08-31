# frozen_string_literal: true

class AddTimezoneToDastProfileSchedules < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  # We disable these cops here because adding the column is safe. The table does not
  # have any data in it as it's behind a feature flag.
  # rubocop: disable Rails/NotNullColumn
  def up
    execute('DELETE FROM dast_profile_schedules')

    unless column_exists?(:dast_profile_schedules, :timezone)
      add_column :dast_profile_schedules, :timezone, :text, null: false
    end

    add_text_limit :dast_profile_schedules, :timezone, 255
  end

  def down
    return unless column_exists?(:dast_profile_schedules, :timezone)

    remove_column :dast_profile_schedules, :timezone
  end
end
