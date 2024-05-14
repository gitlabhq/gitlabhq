# frozen_string_literal: true

class MigrateApplicationSettingsHelpText < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class MigrationApplicationSettings < MigrationRecord
    self.table_name = 'application_settings'
  end

  def up
    count = MigrationApplicationSettings.count

    if count != 1
      ::Gitlab::BackgroundMigration::Logger.error(
        message: "There is more or less than 1 application_settings table (#{count} tables)."
      )
      return
    end

    setting = MigrationApplicationSettings.last
    sign_in_text = setting.sign_in_text
    help_text = setting.help_text

    return if sign_in_text.blank? && help_text.blank?

    # there should be only 1 appearances record but if there is data inconsistency
    # and there are more, it is ok to change all of them

    # we don't have help_text_html so
    # we need to set description_html to nil so that it is regenerated when the field is requested
    execute(<<~SQL)
      UPDATE appearances SET description = CONCAT_WS('\n\n', NULLIF(description, ''),  NULLIF(#{quote(sign_in_text)}, ''), NULLIF(#{quote(help_text)}, '')), description_html = NULL
    SQL
    execute "UPDATE application_settings SET sign_in_text = '', help_text = ''"
  end

  # one-way migration
  def down; end
end
